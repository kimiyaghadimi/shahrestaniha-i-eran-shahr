<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xml="http://www.w3.org/XML/1998/namespace">

  <xsl:output method="html" encoding="UTF-8" indent="yes"/>

  <!-- entry point --> 
  <xsl:template match="/">
    <xsl:apply-templates select="//text"/>
  </xsl:template>

  <!-- table shell and column titles -->
  <xsl:template match="text">
    <table class="analysis-table">
      <thead>
        <tr>
          <th class="col-line">Line</th>
          <th class="col-city">City / Region</th>
          <th class="col-dir">Direction</th>
          <th class="col-people">People</th>
          <th class="col-buildings">Buildings / Objects</th>
          <th class="col-reign">Reign</th>
          <th class="col-text">Text</th>
        </tr>
      </thead>
      <tbody>
        <xsl:apply-templates select="s"/>
      </tbody>
    </table>
  </xsl:template>

  <!-- one row per sentence -->
  <xsl:template match="s">
    <xsl:variable name="sn"  select="@n"/>
    <xsl:variable name="pal" select="seg[@xml:lang='pal']"/>
    <xsl:variable name="eng" select="seg[@xml:lang='en']"/>

    <!-- row trigger -->
    <xsl:variable name="emit">
      <xsl:choose>
        <xsl:when test="$pal//placeName[@type='city']">yes</xsl:when>
        <xsl:when test="$pal//placeName[@type='region']">yes</xsl:when>
        <xsl:when test="$pal//placeName[@type='district']">yes</xsl:when>
        <xsl:when test="$pal//geogName[@type='mountain range' or @type='mountain-range']">yes</xsl:when>
        <xsl:when test="$pal//listPerson[contains(@type,'mountaineer')]">yes</xsl:when>
        <xsl:when test="$pal//persName[@role='sovereign']">yes</xsl:when>
        <xsl:when test="$pal//placeName[@type='fire-temple' and @ref]">yes</xsl:when>
        <xsl:when test="$pal//placeName[@type='residence of demons' or @type='idol temple' or @type='heathen temple']">yes</xsl:when>
        <xsl:otherwise>no</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:if test="$emit = 'yes'">
      <xsl:variable name="dclass">
        <xsl:call-template name="dir-class"><xsl:with-param name="sn" select="$sn"/></xsl:call-template>
      </xsl:variable>
      <tr class="row-{$dclass}" data-sentence="{$sn}">
        <td class="col-line"><xsl:value-of select="$sn"/></td>
        <td class="col-city"><xsl:call-template name="emit-cities"><xsl:with-param name="pal" select="$pal"/><xsl:with-param name="sn" select="$sn"/></xsl:call-template></td>
        <td class="col-dir"><xsl:call-template name="direction-label"><xsl:with-param name="sn" select="$sn"/></xsl:call-template></td>
        <td class="col-people"><xsl:call-template name="emit-people"><xsl:with-param name="pal" select="$pal"/></xsl:call-template></td>
        <td class="col-buildings"><xsl:call-template name="emit-buildings"><xsl:with-param name="pal" select="$pal"/></xsl:call-template></td>
        <td class="col-reign"><xsl:call-template name="emit-reign"><xsl:with-param name="pal" select="$pal"/></xsl:call-template></td>
        <!-- Pahlavi text with supplied stripped; English below -->
        <td class="col-text">
          <span class="text-pal">
            <xsl:apply-templates select="$pal" mode="strip-supplied"/>
          </span>
          <span class="text-eng"><xsl:value-of select="normalize-space($eng)"/></span>
        </td>
      </tr>
    </xsl:if>
  </xsl:template>

  <!-- strip supplied elements from Pahlavi text output -->
  <xsl:template match="*" mode="strip-supplied">
    <xsl:apply-templates select="node()" mode="strip-supplied"/>
  </xsl:template>
  <xsl:template match="supplied" mode="strip-supplied"/><!-- suppress supplied content -->
  <xsl:template match="text()" mode="strip-supplied">
    <xsl:value-of select="."/>
  </xsl:template>

<!--cities column-->
  <xsl:template name="emit-cities">
    <xsl:param name="pal"/>
    <xsl:param name="sn"/>

    <!--
      "N cities" only from num that is a direct child of seg AND the sentence
      is a bulk-city sentence (§28=21, §32=9, §33=24).
      Suppress when: sentence has a listPerson (s6, s29 — num counts abodes/people not cities)
      or has a term[@type='chapter'] (s4 — 1200 is chapters not cities).
    -->
    <xsl:if test="not($pal//listPerson) and not($pal//term[@type='chapter'])">
      <xsl:for-each select="$pal/num[@value]">
        <span class="city-count"><xsl:value-of select="@value"/> cities</span>
      </xsl:for-each>
    </xsl:if>

    <!-- city-group label -->
    <xsl:for-each select="$pal//placeName[@type='city-group']">
      <span class="city-group"><xsl:value-of select="normalize-space(.)"/></span>
    </xsl:for-each>

    <!-- §6: sugd shown as city name + haft āšyān sub-entry -->
    <xsl:for-each select="$pal//placeName[@xml:id='sugd']">
      <span class="city-name">sugd</span>
      <xsl:variable name="haft" select="num/@value"/>
      <xsl:variable name="ashyan" select="normalize-space(term)"/>
      <xsl:if test="$haft != '' and $ashyan != ''">
        <span class="city-sub"><xsl:value-of select="$haft"/>&#160;<xsl:value-of select="$ashyan"/></span>
      </xsl:if>
    </xsl:for-each>

    <!-- individual city names — deduplicated, skip sugd (handled above) -->
    <xsl:for-each select="$pal//placeName[@type='city' and not(@xml:id='sugd')]">
      <xsl:variable name="pos"  select="position()"/>
      <xsl:variable name="name" select="normalize-space(.)"/>
      <xsl:variable name="seen">
        <xsl:for-each select="$pal//placeName[@type='city' and not(@xml:id='sugd')]">
          <xsl:if test="position() &lt; $pos and normalize-space(.)=$name">x</xsl:if>
        </xsl:for-each>
      </xsl:variable>
      <xsl:if test="not(contains($seen,'x')) and $name != ''">
        <span class="city-name">
          <xsl:value-of select="$name"/>
          <xsl:if test="@subtype='estate'">
            <xsl:text>&#160;</xsl:text><span class="city-sub-label">(estate)</span>
          </xsl:if>
        </span>
      </xsl:if>
    </xsl:for-each>

    <!-- region names — skip sugd, skip zamīg restatements -->
    <xsl:for-each select="$pal//placeName[@type='region' and @xml:id!='sugd']">
      <xsl:variable name="rname" select="normalize-space(.)"/>
      <xsl:variable name="dup">
        <xsl:for-each select="$pal//placeName[@type='city']">
          <xsl:if test="normalize-space(.)=$rname">x</xsl:if>
        </xsl:for-each>
      </xsl:variable>
      <xsl:if test="not(contains($dup,'x')) and $rname != '' and not(contains($rname,'zamīg'))">
        <span class="region-name"><xsl:value-of select="$rname"/></span>
      </xsl:if>
    </xsl:for-each>

    <!-- districts (nihāwand 27) -->
    <xsl:for-each select="$pal//placeName[@type='district']">
      <xsl:if test="normalize-space(.) != ''">
        <span class="region-name"><xsl:value-of select="normalize-space(.)"/></span>
      </xsl:if>
    </xsl:for-each>

    <!-- mountain range (28) -->
    <xsl:for-each select="$pal//geogName[@type='mountain range' or @type='mountain-range']">
      <span class="region-name"><xsl:value-of select="normalize-space(.)"/></span>
    </xsl:for-each>

    <!-- §29 mountaineer list: show padišxwārgar from preceding sentence -->
    <xsl:for-each select="$pal//listPerson[contains(@type,'mountaineer')]">
      <xsl:for-each select="//s[number(@n) &lt; number($sn)]//geogName[@type='mountain range' or @type='mountain-range']">
        <xsl:sort select="ancestor::s/@n" data-type="number" order="descending"/>
        <xsl:if test="position()=1">
          <span class="region-name"><xsl:value-of select="normalize-space(.)"/></span>
        </xsl:if>
      </xsl:for-each>
    </xsl:for-each>

    <!-- §30 sovereign continuation -->
    <xsl:if test="$pal//persName[@role='sovereign'] and not($pal//listPerson[contains(@type,'mountaineer')])">
      <xsl:for-each select="//s[number(@n) &lt; number($sn)]//geogName[@type='mountain range' or @type='mountain-range']">
        <xsl:sort select="ancestor::s/@n" data-type="number" order="descending"/>
        <xsl:if test="position()=1">
          <span class="region-name"><xsl:value-of select="normalize-space(.)"/></span>
        </xsl:if>
      </xsl:for-each>
    </xsl:if>

    <!-- continuation sentences -->
    <xsl:if test="not($pal//placeName[@type='city'])
                  and not($pal//placeName[@type='region'])
                  and not($pal//placeName[@type='district'])
                  and not($pal//geogName[@type='mountain range' or @type='mountain-range'])
                  and not($pal//listPerson[contains(@type,'mountaineer')])
                  and not($pal//persName[@role='sovereign'])">
      <!-- fire-temple continuation: show the city the fire-temple belongs to.
           Only use @ref if it points to an xml:id that is a city, not another fire-temple.
           This prevents s4 showing atash-wahram-samarkand (a fire-temple ref, not a city). -->
      <xsl:for-each select="($pal//placeName[@type='fire-temple' and @ref])[1]">
        <xsl:variable name="ftref" select="@ref"/>
        <xsl:if test="//placeName[@xml:id=$ftref and @type='city']">
          <span class="city-name cont"><xsl:value-of select="$ftref"/></span>
        </xsl:if>
      </xsl:for-each>
      <!-- rs place-reference fallback: for structure-only sentences (§7) where the place
           is given only as an anaphoric reference. Shows @ref value directly — now "sugd" after cleanup. -->
      <xsl:for-each select="($pal//rs[@type='place-reference' and @ref])[1]">
        <span class="region-name"><xsl:value-of select="@ref"/></span>
      </xsl:for-each>
    </xsl:if>

    <!-- prison aliases (§49) -->
    <xsl:for-each select="$pal//placeName[@type='prison']">
      <xsl:variable name="pname" select="normalize-space(.)"/>
      <xsl:variable name="pid"   select="@xml:id"/>
      <xsl:if test="$pname != ''">
        <span class="city-alias">
          <xsl:value-of select="$pname"/>
          <xsl:if test="contains($pid,'eran-shahr')"><xsl:text> ī Ērān-šahr</xsl:text></xsl:if>
        </span>
      </xsl:if>
    </xsl:for-each>

  </xsl:template>

<!--people column-->

  <xsl:template name="emit-people">
    <xsl:param name="pal"/>

    <!-- 40 three lords: standalone roleName[@type='lord'] -->
    <xsl:for-each select="$pal//roleName[@type='lord'][not(ancestor::persName)]">
      <span class="person-entry">
        <span class="person-name"><xsl:value-of select="normalize-space(.)"/></span>
        <span class="person-role">builder</span>
      </span>
    </xsl:for-each>

    <!-- mountaineers standalone roleName suppressed — it's a group label (kōfyār), not a person name.
         The individual mountaineers are listed via the listPerson block below. -->

    <!-- King of Kings standalone (33) -->
    <xsl:for-each select="$pal//roleName[@type='King of Kings'][not(ancestor::persName)]">
      <span class="person-entry">
        <span class="person-name"><xsl:value-of select="normalize-space(.)"/></span>
        <span class="person-role">builder</span>
      </span>
    </xsl:for-each>

    <!-- main persName loop -->
    <xsl:for-each select="$pal//persName[
        not(@type='nickname') and
        not(ancestor::date) and
        not(ancestor::relation) and
        not(ancestor::listPerson) and
        not(ancestor::placeName)
      ]">

      <xsl:variable name="my-id"  select="@xml:id"/>
      <xsl:variable name="my-ref" select="@ref"/>
      <xsl:variable name="fn"     select="normalize-space(forename|foreName)"/>
      <xsl:variable name="rl"     select="normalize-space(roleName[not(@type='King of Kings') and not(@type='mountaineers') and not(@type='lord')])"/>
      <xsl:variable name="pat"    select="normalize-space(addName[@type='patronymic' or @type='patronynic'])"/>
      <xsl:variable name="tek"    select="normalize-space(addName[@type='teknonymic'])"/>

      <!-- enclitic detection -->
      <xsl:variable name="direct-text">
        <xsl:value-of select="normalize-space(text())"/>
        <xsl:for-each select="*[not(self::supplied) and not(self::relation)]">
          <xsl:value-of select="normalize-space(.)"/>
        </xsl:for-each>
      </xsl:variable>
      <xsl:variable name="is-enclitic">
        <xsl:if test="$fn='' and $rl='' and normalize-space($direct-text)='' and supplied">yes</xsl:if>
      </xsl:variable>

      <!-- display name priority: forename > roleName > bare text -->
      <xsl:variable name="display-name">
        <xsl:choose>
          <xsl:when test="$fn != ''"><xsl:value-of select="$fn"/></xsl:when>
          <xsl:when test="$rl != ''"><xsl:value-of select="$rl"/></xsl:when>
          <xsl:otherwise><xsl:value-of select="normalize-space(.)"/></xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <!-- canonical key for dedup -->
      <xsl:variable name="person-key">
        <xsl:choose>
          <xsl:when test="$my-id != ''"><xsl:value-of select="$my-id"/></xsl:when>
          <xsl:when test="$my-ref != ''"><xsl:value-of select="$my-ref"/></xsl:when>
          <xsl:otherwise><xsl:value-of select="$display-name"/></xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <xsl:if test="normalize-space($display-name) != '' and $is-enclitic != 'yes'">

        <!-- dedup: only emit first non-enclitic occurrence -->
        <xsl:variable name="mypos" select="position()"/>
        <xsl:variable name="seen-before">
          <xsl:for-each select="$pal//persName[
              not(@type='nickname') and not(ancestor::date) and
              not(ancestor::relation) and not(ancestor::listPerson) and not(ancestor::placeName)
            ]">
            <xsl:variable name="ofn" select="normalize-space(forename|foreName)"/>
            <xsl:variable name="orl" select="normalize-space(roleName[not(@type='King of Kings') and not(@type='mountaineers') and not(@type='lord')])"/>
            <xsl:variable name="odt">
              <xsl:value-of select="normalize-space(text())"/>
              <xsl:for-each select="*[not(self::supplied) and not(self::relation)]">
                <xsl:value-of select="normalize-space(.)"/>
              </xsl:for-each>
            </xsl:variable>
            <xsl:variable name="oenc">
              <xsl:if test="$ofn='' and $orl='' and normalize-space($odt)='' and supplied">yes</xsl:if>
            </xsl:variable>
            <xsl:variable name="okey">
              <xsl:choose>
                <xsl:when test="@xml:id != ''"><xsl:value-of select="@xml:id"/></xsl:when>
                <xsl:when test="@ref != ''"><xsl:value-of select="@ref"/></xsl:when>
                <xsl:otherwise>
                  <xsl:choose>
                    <xsl:when test="$ofn != ''"><xsl:value-of select="$ofn"/></xsl:when>
                    <xsl:when test="$orl != ''"><xsl:value-of select="$orl"/></xsl:when>
                    <xsl:otherwise><xsl:value-of select="normalize-space(.)"/></xsl:otherwise>
                  </xsl:choose>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <xsl:if test="$oenc != 'yes' and position() &lt; $mypos and $okey = $person-key">x</xsl:if>
          </xsl:for-each>
        </xsl:variable>

        <xsl:if test="not(contains($seen-before,'x'))">

          <!-- collect all roles including from enclitic mentions -->
          <xsl:variable name="all-roles">
            <xsl:for-each select="$pal//persName[
                not(@type='nickname') and not(ancestor::date) and
                not(ancestor::relation) and not(ancestor::listPerson) and not(ancestor::placeName)
              ]">
              <xsl:variable name="ofn" select="normalize-space(forename|foreName)"/>
              <xsl:variable name="orl" select="normalize-space(roleName[not(@type='King of Kings') and not(@type='mountaineers') and not(@type='lord')])"/>
              <xsl:variable name="okey">
                <xsl:choose>
                  <xsl:when test="@xml:id != ''"><xsl:value-of select="@xml:id"/></xsl:when>
                  <xsl:when test="@ref != ''"><xsl:value-of select="@ref"/></xsl:when>
                  <xsl:otherwise>
                    <xsl:choose>
                      <xsl:when test="$ofn != ''"><xsl:value-of select="$ofn"/></xsl:when>
                      <xsl:when test="$orl != ''"><xsl:value-of select="$orl"/></xsl:when>
                      <xsl:otherwise><xsl:value-of select="normalize-space(.)"/></xsl:otherwise>
                    </xsl:choose>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:variable>
              <xsl:if test="$okey = $person-key and @role != ''">
                <xsl:value-of select="@role"/>|
              </xsl:if>
            </xsl:for-each>
          </xsl:variable>

          <span class="person-entry">
            <!-- pejorative epithet before name — skip if it's the 59 roleName case -->
            <xsl:if test="not(roleName[@type='religious'] and addName[@type='epithet' and @subtype='pejorative'])">
              <xsl:for-each select="addName[@type='epithet' and @subtype='pejorative']">
                <span class="epithet-neg"><xsl:value-of select="normalize-space(.)"/><xsl:text> </xsl:text></span>
              </xsl:for-each>
            </xsl:if>
            <!-- person name -->
            <span class="person-name">
              <xsl:choose>
                <!-- 37: forename ī roleName[@type='king'] -->
                <xsl:when test="$fn != '' and roleName[@type='king']">
                  <xsl:value-of select="$fn"/>
                  <xsl:text> ī </xsl:text>
                  <xsl:value-of select="normalize-space(roleName[@type='king'])"/>
                </xsl:when>
                <!-- 59: roleName ī pejorative addName — zandīg ī purr-marg -->
                <xsl:when test="roleName[@type='religious'] and addName[@type='epithet' and @subtype='pejorative']">
                  <xsl:value-of select="normalize-space(roleName[@type='religious'])"/>
                  <xsl:text> </xsl:text>
                  <xsl:value-of select="normalize-space(addName[@type='epithet' and @subtype='pejorative'])"/>
                </xsl:when>
                <xsl:otherwise><xsl:value-of select="$display-name"/></xsl:otherwise>
              </xsl:choose>
            </span>
            <!-- patronymic with ī connector -->
            <xsl:if test="$pat != ''">
              <span class="person-pat"> ī <xsl:value-of select="$pat"/></span>
            </xsl:if>
            <!-- teknonymic with ī -->
            <xsl:if test="$tek != ''">
              <span class="person-pat"> ī <xsl:value-of select="$tek"/></span>
            </xsl:if>
            <!-- praise epithet — shown plain without quotes -->
            <xsl:for-each select="addName[@type='epithet' and @subtype='praise']">
              <span class="epithet-pos"><xsl:text> </xsl:text><xsl:value-of select="normalize-space(.)"/></span>
            </xsl:for-each>
            <!-- merged role badges -->
            <xsl:call-template name="render-roles">
              <xsl:with-param name="roles" select="$all-roles"/>
            </xsl:call-template>
            <!-- ethnic origin -->
            <xsl:for-each select="addName[@type='origin']/rs[@type='ethnicity']">
              <span class="person-ethnic"><xsl:value-of select="normalize-space(.)"/></span>
            </xsl:for-each>
            <!-- nickname -->
            <xsl:for-each select="$pal//persName[@type='nickname']">
              <xsl:variable name="nref" select="@ref"/>
              <xsl:if test="($my-id != '' and $nref = $my-id) or ($my-ref != '' and $nref = $my-ref)">
                <span class="person-nickname">also: <xsl:value-of select="normalize-space(.)"/></span>
              </xsl:if>
            </xsl:for-each>
          </span>

        </xsl:if>
      </xsl:if>
    </xsl:for-each>

    <!-- seven lords people list (6) — shown as proper person entries like any other name -->
    <xsl:for-each select="$pal//listPerson[contains(@type,'lords') or contains(@corresp,'seven-lords')]">
      <xsl:for-each select="person">
        <span class="person-entry">
          <span class="person-name"><xsl:value-of select="normalize-space(persName)"/></span>
          <xsl:if test="persName/@role != ''">
            <span class="person-role"><xsl:value-of select="persName/@role"/></span>
          </xsl:if>
        </span>
      </xsl:for-each>
    </xsl:for-each>

    <!-- seven mountaineers people list (29) — shown as proper person entries, no "kōfyār" heading -->
    <xsl:for-each select="$pal//listPerson[contains(@type,'mountaineer') or contains(@corresp,'mountaineer')]">
      <xsl:for-each select="person/persName">
        <span class="person-entry">
          <span class="person-name"><xsl:value-of select="normalize-space(.)"/></span>
          <xsl:if test="@role != ''">
            <span class="person-role"><xsl:value-of select="@role"/></span>
          </xsl:if>
        </span>
      </xsl:for-each>
    </xsl:for-each>

    <!-- succession list: "succession: x → y → z" (14) -->
    <xsl:for-each select="$pal//listPerson[contains(@type,'succession')]">
      <span class="person-note">
        <xsl:text>succession: </xsl:text>
        <xsl:for-each select="person">
          <xsl:value-of select="normalize-space(persName)"/>
          <xsl:if test="position() != last()"><xsl:text> → </xsl:text></xsl:if>
        </xsl:for-each>
      </span>
    </xsl:for-each>

  </xsl:template>

  <!-- render pipe-separated role list as badges -->
  <xsl:template name="render-roles">
    <xsl:param name="roles"/>
    <xsl:if test="normalize-space($roles) != ''">
      <xsl:variable name="first">
        <xsl:choose>
          <xsl:when test="contains($roles,'|')"><xsl:value-of select="normalize-space(substring-before($roles,'|'))"/></xsl:when>
          <xsl:otherwise><xsl:value-of select="normalize-space($roles)"/></xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:variable name="rest">
        <xsl:if test="contains($roles,'|')"><xsl:value-of select="substring-after($roles,'|')"/></xsl:if>
      </xsl:variable>
      <xsl:if test="$first != ''">
        <span class="person-role"><xsl:value-of select="$first"/></span>
      </xsl:if>
      <xsl:if test="normalize-space($rest) != ''">
        <xsl:call-template name="render-roles"><xsl:with-param name="roles" select="$rest"/></xsl:call-template>
      </xsl:if>
    </xsl:if>
  </xsl:template>


  <!--building column -->
  <xsl:template name="emit-buildings">
    <xsl:param name="pal"/>

    <xsl:variable name="has" select="$pal//placeName[
        @type='fire-temple' or @type='bridge' or @type='fortress' or
        @type='harem' or @type='tower' or @type='wall' or
        @type='estate' or @type='treasury' or @type='residence' or
        @type='idol temple' or @type='heathen temple' or
        @type='residence of demons'
      ] | $pal//placeName[@type='city' and @subtype='estate']
        | $pal//objectName | $pal//measure |
      $pal//rs[@type='planet' or @type='constellation' or @type='heavenly-sphere' or @type='sun'] |
      $pal//roleName[@type='military-unit']"/>

    <xsl:if test="not($has)"><span class="none">—</span></xsl:if>

    <!-- physical structures — deduplicated -->
    <xsl:for-each select="$pal//placeName[
        @type='fire-temple' or @type='bridge' or @type='fortress' or
        @type='harem' or @type='tower' or @type='wall' or
        @type='estate' or @type='treasury' or @type='residence' or
        @type='idol temple' or @type='heathen temple' or
        @type='residence of demons'
      ]">
      <xsl:variable name="pos"   select="position()"/>
      <xsl:variable name="btype" select="@type"/>
      <xsl:variable name="bname" select="normalize-space(.)"/>
      <xsl:variable name="seen">
        <xsl:for-each select="$pal//placeName[
            @type='fire-temple' or @type='bridge' or @type='fortress' or
            @type='harem' or @type='tower' or @type='wall' or
            @type='estate' or @type='treasury' or @type='residence' or
            @type='idol temple' or @type='heathen temple' or
            @type='residence of demons'
          ]">
          <xsl:if test="position() &lt; $pos and normalize-space(.)=$bname and @type=$btype">x</xsl:if>
        </xsl:for-each>
      </xsl:variable>
      <xsl:if test="not(contains($seen,'x'))">
        <!-- build type label: include subtype if present (e.g. fire-temple treasury) -->
        <xsl:variable name="type-label">
          <xsl:choose>
            <xsl:when test="@subtype != ''">
              <xsl:value-of select="$btype"/>
              <xsl:text> (</xsl:text>
              <xsl:value-of select="@subtype"/>
              <xsl:text>)</xsl:text>
            </xsl:when>
            <xsl:otherwise><xsl:value-of select="$btype"/></xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <span class="building-entry btype-{translate($btype,' ','-')}">
          <span class="building-type"><xsl:value-of select="$type-label"/></span>
          <xsl:if test="$bname != ''">
            <span class="building-name"><xsl:value-of select="$bname"/></span>
          </xsl:if>
        </span>
      </xsl:if>
    </xsl:for-each>

    <!-- §20 wall measures — Pahlavi text as uppercased label, @key as description -->
    <xsl:if test="$pal//placeName[@type='wall']">
      <xsl:for-each select="$pal//measure">
        <span class="building-entry btype-measure">
          <span class="building-type"><xsl:value-of select="normalize-space(.)"/></span>
          <span class="building-name">
            <xsl:choose>
              <xsl:when test="@key != ''"><xsl:value-of select="@key"/></xsl:when>
              <xsl:otherwise><xsl:value-of select="@unit"/></xsl:otherwise>
            </xsl:choose>
          </span>
        </span>
      </xsl:for-each>
    </xsl:if>

    <!-- §20 dastgird as estate in buildings column -->
    <xsl:for-each select="$pal//placeName[@type='city' and @subtype='estate']">
      <span class="building-entry btype-estate">
        <span class="building-type">estate</span>
        <span class="building-name"><xsl:value-of select="normalize-space(.)"/></span>
      </span>
    </xsl:for-each>

    <!-- named objects (golden tablets §4) -->
    <xsl:for-each select="$pal//objectName">
      <span class="building-entry btype-object">
        <span class="building-type">object</span>
        <span class="building-name"><xsl:value-of select="normalize-space(.)"/></span>
      </span>
    </xsl:for-each>

    <!-- military units: subtype/key format (§52 cavalry/dō-sar, grey-troops/bor-gil) -->
    <xsl:for-each select="$pal//roleName[@type='military-unit']">
      <span class="building-entry btype-military">
        <span class="building-type">military unit</span>
        <span class="building-name">
          <xsl:value-of select="normalize-space(.)"/>
          <xsl:text> (</xsl:text>
          <xsl:if test="@subtype != ''"><xsl:value-of select="@subtype"/></xsl:if>
          <xsl:if test="@subtype != '' and @key != ''">/</xsl:if>
          <xsl:if test="@key != ''"><xsl:value-of select="@key"/></xsl:if>
          <xsl:text>)</xsl:text>
        </span>
      </span>
    </xsl:for-each>

    <!-- celestial bodies (§24) -->
    <xsl:if test="$pal//rs[@type='planet' or @type='constellation' or @type='heavenly-sphere' or @type='sun']">
      <span class="building-entry btype-celestial">
        <span class="building-type">celestial bodies</span>
        <span class="building-name">
          <xsl:for-each select="$pal//rs[@type='planet' or @type='constellation' or @type='heavenly-sphere' or @type='sun']">
            <xsl:value-of select="normalize-space(.)"/>
            <xsl:if test="position() != last()"><xsl:text>, </xsl:text></xsl:if>
          </xsl:for-each>
        </span>
      </span>
    </xsl:if>

  </xsl:template>


  <!-- ═══════════════════════════════════
       REIGN COLUMN
       ═══════════════════════════════════ -->
  <xsl:template name="emit-reign">
    <xsl:param name="pal"/>
    <xsl:choose>
      <xsl:when test="$pal//date">
        <xsl:for-each select="$pal//date">
          <span class="reign-entry">
            <xsl:choose>
              <xsl:when test="@dur != ''">
                <xsl:call-template name="parse-dur"><xsl:with-param name="dur" select="@dur"/></xsl:call-template>
              </xsl:when>
              <xsl:when test="@type='reign'">
                <xsl:choose>
                  <xsl:when test="@subtype='evil'">evil reign — </xsl:when>
                  <xsl:otherwise>reign — </xsl:otherwise>
                </xsl:choose>
                <xsl:variable name="rfn"   select="normalize-space(.//persName/forename | .//persName/foreName)"/>
                <xsl:variable name="rpat"  select="normalize-space(.//persName/addName[@type='patronymic' or @type='patronynic'])"/>
                <xsl:variable name="rbare" select="normalize-space(.//persName)"/>
                <xsl:choose>
                  <xsl:when test="$rfn != ''">
                    <xsl:value-of select="$rfn"/>
                    <xsl:if test="$rpat != ''"><xsl:text> ī </xsl:text><xsl:value-of select="$rpat"/></xsl:if>
                  </xsl:when>
                  <xsl:when test="$rbare != ''"><xsl:value-of select="$rbare"/></xsl:when>
                </xsl:choose>
              </xsl:when>
              <xsl:otherwise><xsl:value-of select="normalize-space(.)"/></xsl:otherwise>
            </xsl:choose>
          </span>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise><span class="none">—</span></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- strips ISO 8601 duration: P900Y → "900 years" -->
  <xsl:template name="parse-dur">
    <xsl:param name="dur"/>
    <xsl:variable name="body" select="substring-after($dur,'P')"/>
    <xsl:choose>
      <xsl:when test="contains($body,'Y')"><xsl:value-of select="substring-before($body,'Y')"/> years</xsl:when>
      <xsl:otherwise><xsl:value-of select="$dur"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <!-- ═══════════════════════════════════
       DIRECTION HELPERS
       ═══════════════════════════════════ -->
  <xsl:template name="current-direction">
    <xsl:param name="sn"/>
    <xsl:variable name="here" select="//s[@n=$sn]//geogName[@type='direction']/@subtype"/>
    <xsl:choose>
      <xsl:when test="$here != ''"><xsl:value-of select="$here"/></xsl:when>
      <xsl:otherwise>
        <xsl:for-each select="//s[number(@n) &lt; number($sn)]//geogName[@type='direction']">
          <xsl:sort select="ancestor::s/@n" data-type="number" order="descending"/>
          <xsl:if test="position()=1"><xsl:value-of select="@subtype"/></xsl:if>
        </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="dir-class">
    <xsl:param name="sn"/>
    <xsl:variable name="d"><xsl:call-template name="current-direction"><xsl:with-param name="sn" select="$sn"/></xsl:call-template></xsl:variable>
    <xsl:choose>
      <xsl:when test="contains($d,'northeast')">ne</xsl:when>
      <xsl:when test="contains($d,'southwest')">sw</xsl:when>
      <xsl:when test="contains($d,'southeast')">se</xsl:when>
      <xsl:when test="contains($d,'northwest')">nw</xsl:when>
      <xsl:otherwise>unknown</xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="direction-label">
    <xsl:param name="sn"/>
    <xsl:variable name="d"><xsl:call-template name="current-direction"><xsl:with-param name="sn" select="$sn"/></xsl:call-template></xsl:variable>
    <xsl:choose>
      <xsl:when test="contains($d,'northeast')">Northeast</xsl:when>
      <xsl:when test="contains($d,'southwest')">Southwest</xsl:when>
      <xsl:when test="contains($d,'southeast')">Southeast</xsl:when>
      <xsl:when test="contains($d,'northwest')">Northwest</xsl:when>
      <xsl:otherwise>—</xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
