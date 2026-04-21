<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xml="http://www.w3.org/XML/1998/namespace">
    
    <xsl:output method="html" encoding="UTF-8" indent="yes"/>
    
    <!-- ── Full HTML page ── -->
    <xsl:template match="/">
        <html>
            <head>
                <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
                <meta charset="UTF-8"/>
                <title>Šahrestānīhā ī Ērānšahr</title>
                <link rel="stylesheet" href="webstyle.css"/>
            </head>
            <body>

                <!-- Nav -->
                <nav>
                    <span class="nav-title">Šahrestānīhā ī Ērānšahr</span>
                    <div class="nav-right">
                        <span class="nav-label" id="theme-label">Light</span>
                        <button class="theme-toggle" id="themeToggle" aria-label="Toggle dark mode"></button>
                    </div>
                </nav>

                <!-- Page header -->
                <header class="page-header">
                    <p class="work-eyebrow">Middle Persian · Book Pahlavi</p>
                    <h1 class="work-title">Šahrestānīhā ī Ērānšahr</h1>
                    <p class="work-subtitle">The Provincial Capitals of Ērānšahr</p>
                </header>

                <!-- Edition -->
                <main class="edition">
                    <xsl:apply-templates/>
                </main>

                <footer>Middle Persian · Book Pahlavi · Digital Edition</footer>

                <!-- Theme toggle script -->
                <script>
                    (function() {
                        var toggle = document.getElementById('themeToggle');
                        var label  = document.getElementById('theme-label');
                        var html   = document.documentElement;

                        var saved = localStorage.getItem('pahlaviTheme');
                        if (saved) {
                            html.setAttribute('data-theme', saved);
                            label.textContent = saved === 'dark' ? 'Dark' : 'Light';
                        }

                        toggle.addEventListener('click', function() {
                            var next = html.getAttribute('data-theme') === 'dark' ? 'light' : 'dark';
                            html.setAttribute('data-theme', next);
                            label.textContent = next === 'dark' ? 'Dark' : 'Light';
                            localStorage.setItem('pahlaviTheme', next);
                        });
                    })();
                </script>

                <!-- Manuscript image toggle script -->
                <script>
                    document.addEventListener('click', function(e) {
                        var btn = e.target.closest('.ms-toggle');
                        if (!btn) return;
                        var lineId = btn.getAttribute('data-line');
                        var panel  = document.getElementById('ms-' + lineId);
                        if (panel) panel.classList.toggle('visible');
                    });
                </script>

            </body>
        </html>
    </xsl:template>
    
    <!-- ── Each line ── -->
    <xsl:template match="ab[@type='line']">
        <xsl:variable name="lineId" select="@xml:id"/>
        <xsl:variable name="lineNum" select="substring-after($lineId, 'line')"/>

        <div class="line">
            <xsl:attribute name="id">
                <xsl:value-of select="$lineId"/>
            </xsl:attribute>

            <!-- meta row: number + manuscript image button -->
            <div class="line-meta">
                <span class="line-num">
                    <xsl:value-of select="$lineNum"/>
                </span>
                <button class="ms-toggle" title="Show manuscript">
                    <xsl:attribute name="data-line">
                        <xsl:value-of select="$lineId"/>
                    </xsl:attribute>
                    <!-- image / photograph icon (SVG inline) -->
                    <svg viewBox="0 0 24 24" aria-hidden="true">
                        <rect x="3" y="5" width="18" height="14" rx="2"/>
                        <circle cx="12" cy="12" r="3"/>
                        <path d="M3 9l3-3 3 3"/>
                    </svg>
                </button>
            </div>

            <!-- manuscript image panel (hidden by default) -->
            <div class="ms-image">
                <xsl:attribute name="id">ms-<xsl:value-of select="$lineId"/></xsl:attribute>
                <img alt="Manuscript image for line {$lineNum}">
                    <xsl:attribute name="src">
                        <xsl:value-of select="$lineId"/>.png</xsl:attribute>
                </img>
            </div>

            <!-- Pahlavi script -->
            <div class="pahlavi-line">
                <xsl:apply-templates select="seg[@type='unit']"/>
            </div>

            <!-- Transliteration -->
            <div class="transcription-line">
                <xsl:value-of select="cit[@type='transcription']/quote"/>
            </div>

            <!-- Translation -->
            <div class="translation-line">
                <xsl:value-of select="cit[@type='translation']/quote"/>
            </div>
        </div>
    </xsl:template>
    
    <!-- ── Each word unit ── -->
    <xsl:template match="seg[@type='unit']">
        <span class="unit">
            <xsl:attribute name="id">
                <xsl:value-of select="@xml:id"/>
            </xsl:attribute>
            <xsl:attribute name="data-transcrip">
                <xsl:value-of select="transcrip"/>
            </xsl:attribute>
            <xsl:attribute name="data-gloss">
                <xsl:value-of select="gloss"/>
            </xsl:attribute>
            <span class="pahlavi" dir="rtl">
                <xsl:value-of select="orig"/>
            </span>
        </span>
    </xsl:template>
    
</xsl:stylesheet>
