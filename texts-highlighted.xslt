<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xml="http://www.w3.org/XML/1998/namespace">

  <xsl:output method="html" encoding="UTF-8" indent="yes"/>

  <xsl:template match="/">
    <xsl:apply-templates select="//body"/>
  </xsl:template>

  <xsl:template match="body">
    <div class="text-grid">

      <!-- head -->
      <xsl:for-each select="//head//l">
        <xsl:variable name="full" select="normalize-space(.)"/>
        <xsl:variable name="pal-part">
          <xsl:call-template name="pal-half"><xsl:with-param name="txt" select="$full"/></xsl:call-template>
        </xsl:variable>
        <xsl:variable name="eng-part">
          <xsl:call-template name="eng-half"><xsl:with-param name="txt" select="$full"/></xsl:call-template>
        </xsl:variable>
        <div class="text-row text-row--head">
          <div class="text-linenum">—</div>
          <div class="text-pal"><xsl:value-of select="$pal-part"/></div>
          <div class="text-eng"><xsl:value-of select="$eng-part"/></div>
        </div>
      </xsl:for-each>

      <!-- sentences -->
      <xsl:for-each select="//s">
        <xsl:variable name="sn"  select="@n"/>
        <xsl:variable name="pal" select="seg[@xml:lang='pal']"/>
        <xsl:variable name="eng" select="seg[@xml:lang='en']"/>
        <div class="text-row" data-sentence="{$sn}">
          <div class="text-linenum"><xsl:value-of select="$sn"/></div>
          <div class="text-pal">
            <xsl:apply-templates select="$pal" mode="highlight"/>
          </div>
          <div class="text-eng"><xsl:value-of select="normalize-space($eng)"/></div>
        </div>
      </xsl:for-each>

      <!-- trailer -->
      <xsl:for-each select="//trailer//l">
        <xsl:variable name="full" select="normalize-space(.)"/>
        <xsl:variable name="pal-part">
          <xsl:call-template name="pal-half"><xsl:with-param name="txt" select="$full"/></xsl:call-template>
        </xsl:variable>
        <xsl:variable name="eng-part">
          <xsl:call-template name="eng-half"><xsl:with-param name="txt" select="$full"/></xsl:call-template>
        </xsl:variable>
        <div class="text-row text-row--trailer">
          <div class="text-linenum">—</div>
          <div class="text-pal"><xsl:value-of select="$pal-part"/></div>
          <div class="text-eng"><xsl:value-of select="$eng-part"/></div>
        </div>
      </xsl:for-each>

    </div>
  </xsl:template>

  <!-- head/trailer split helpers -->
  <xsl:template name="pal-half">
    <xsl:param name="txt"/>
    <xsl:param name="pos" select="1"/>
    <xsl:variable name="len" select="string-length($txt)"/>
    <xsl:choose>
      <xsl:when test="$pos >= $len"><xsl:value-of select="$txt"/></xsl:when>
      <xsl:when test="substring($txt,$pos,2)='. ' and contains('ABCDEFGHIJKLMNOPQRSTUVWXYZ',substring($txt,$pos+2,1))">
        <xsl:value-of select="substring($txt,1,$pos)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="pal-half">
          <xsl:with-param name="txt" select="$txt"/>
          <xsl:with-param name="pos" select="$pos + 1"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="eng-half">
    <xsl:param name="txt"/>
    <xsl:param name="pos" select="1"/>
    <xsl:variable name="len" select="string-length($txt)"/>
    <xsl:choose>
      <xsl:when test="$pos >= $len"></xsl:when>
      <xsl:when test="substring($txt,$pos,2)='. ' and contains('ABCDEFGHIJKLMNOPQRSTUVWXYZ',substring($txt,$pos+2,1))">
        <xsl:value-of select="normalize-space(substring($txt,$pos+2))"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="eng-half">
          <xsl:with-param name="txt" select="$txt"/>
          <xsl:with-param name="pos" select="$pos + 1"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <!-- interp: underlined — defined FIRST so it beats the wildcard -->
  <xsl:template match="interp" mode="highlight">
    <span class="hl-interp"><xsl:value-of select="."/></span>
  </xsl:template>

  <!-- suppress -->
  <xsl:template match="supplied" mode="highlight"/>
  <xsl:template match="relation" mode="highlight"/>

  <!-- default: recurse -->
  <xsl:template match="*" mode="highlight">
    <xsl:apply-templates select="node()" mode="highlight"/>
  </xsl:template>

  <xsl:template match="text()" mode="highlight">
    <xsl:value-of select="."/>
  </xsl:template>

  <!-- persName: person colour -->
  <xsl:template match="persName" mode="highlight">
    <span class="hl-person">
      <xsl:apply-templates select="node()" mode="highlight"/>
    </span>
  </xsl:template>

  <!-- roleName[@type='king' or @type='khan']: same person colour as names -->
  <xsl:template match="roleName[@type='king' or @type='khan']" mode="highlight">
    <span class="hl-person">
      <xsl:apply-templates select="node()" mode="highlight"/>
    </span>
  </xsl:template>

  <!-- all other roleName: role colour -->
  <xsl:template match="roleName" mode="highlight">
    <span class="hl-role">
      <xsl:apply-templates select="node()" mode="highlight"/>
    </span>
  </xsl:template>

  <!-- placeName: cities/regions vs buildings -->
  <xsl:template match="placeName[@type='city' or @type='city-group' or @type='district' or @type='region' or @type='mega-region']" mode="highlight">
    <span class="hl-city">
      <xsl:apply-templates select="node()" mode="highlight"/>
    </span>
  </xsl:template>

  <xsl:template match="placeName[@type='fire-temple' or @type='bridge' or @type='fortress' or @type='harem' or @type='tower' or @type='wall' or @type='residence' or @type='prison' or @type='heathen temple' or @type='idol temple' or @type='residence of demons']" mode="highlight">
    <span class="hl-building">
      <xsl:apply-templates select="node()" mode="highlight"/>
    </span>
  </xsl:template>

  <!-- catch-all placeName -->
  <xsl:template match="placeName" mode="highlight">
    <span class="hl-city">
      <xsl:apply-templates select="node()" mode="highlight"/>
    </span>
  </xsl:template>

  <!-- geogName: geographic colour -->
  <xsl:template match="geogName" mode="highlight">
    <span class="hl-geo">
      <xsl:apply-templates select="node()" mode="highlight"/>
    </span>
  </xsl:template>

  <!-- date -->
  <xsl:template match="date" mode="highlight">
    <span class="hl-date">
      <xsl:apply-templates select="node()" mode="highlight"/>
    </span>
  </xsl:template>

  <!-- addName -->
  <xsl:template match="addName[@subtype='pejorative']" mode="highlight">
    <span class="hl-pejorative">
      <xsl:apply-templates select="node()" mode="highlight"/>
    </span>
  </xsl:template>

  <xsl:template match="addName[@subtype='praise']" mode="highlight">
    <span class="hl-praise">
      <xsl:apply-templates select="node()" mode="highlight"/>
    </span>
  </xsl:template>

  <!-- pass-through elements -->
  <xsl:template match="addName|num|term|objectName|forename|foreName|rs|measure" mode="highlight">
    <xsl:apply-templates select="node()" mode="highlight"/>
  </xsl:template>

  <xsl:template match="list|item|listPerson|person|place" mode="highlight">
    <xsl:apply-templates select="node()" mode="highlight"/>
  </xsl:template>

</xsl:stylesheet>
