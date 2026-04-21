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

      <!-- head: each <l> contains "pahlavi text. English text." separated by ". [Capital]" -->
      <xsl:for-each select="//head//l">
        <xsl:variable name="full" select="normalize-space(.)"/>
        <!-- split on first ". " before a capital letter — take up to first ". " as Pahlavi -->
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
            <xsl:call-template name="strip-supplied">
              <xsl:with-param name="node" select="$pal"/>
            </xsl:call-template>
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

  <!--Split "pal text. English text." into the Pahlavi half.
    Strategy: the English part always begins with a capital letter after ". ".
    We find the first occurrence of ". " where the next char is A-Z.
    XSLT 1.0 has no regex, so we walk character by character via recursion.
  -->
  <xsl:template name="pal-half">
    <xsl:param name="txt"/>
    <xsl:param name="pos" select="1"/>
    <xsl:variable name="len" select="string-length($txt)"/>
    <xsl:choose>
      <!-- reached end without finding split — return whole string -->
      <xsl:when test="$pos >= $len">
        <xsl:value-of select="$txt"/>
      </xsl:when>
      <!-- found ". " followed by uppercase letter -->
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
      <xsl:when test="$pos >= $len"><!-- no split found --></xsl:when>
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

  <!-- strip supplied elements, output plain text -->
  <xsl:template name="strip-supplied">
    <xsl:param name="node"/>
    <xsl:for-each select="$node/descendant-or-self::text()[not(ancestor::supplied)]">
      <xsl:value-of select="."/>
    </xsl:for-each>
  </xsl:template>

</xsl:stylesheet>
