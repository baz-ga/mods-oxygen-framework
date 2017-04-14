<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:mods="http://www.loc.gov/mods/v3"
    xmlns:lfn="localfunctions"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:drb="http://www.dartmouth.edu/~library/catmet/"
    xmlns="http://www.crossref.org/schema/4.3.7"
    xsi:schemaLocation="http://www.crossref.org/schema/4.3.7 http://doi.crossref.org/schemas/crossref4.3.7.xsd"
    exclude-result-prefixes="xs xd lfn xsi drb"
    version="2.0">
    
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Sep 16, 2014</xd:p>
            <xd:p><xd:b>Author:</xd:b> Shaun Akhtar</xd:p>
            
            <xd:p>Creates a Crossref DOI submission packet containing data from
                each MODS record (1 per file) passed as input.</xd:p>
            
            <xd:p>Each Crossref packet can only contain one content type (e.g. dissertations,
                databases, books), so ensure that the input found within $source is limited to 
                a single type of material.</xd:p>
            
            <xd:p>Based on export-crossref.xsl for TEI documents by Paul L. Merchant Jr.</xd:p>
            
            <xd:p>Copyright 2014 Trustees of Dartmouth College</xd:p>
        </xd:desc>
    </xd:doc>
    
    <xsl:include href="local-functions.xsl"/>
    
    <xsl:variable name="now" select="format-dateTime(current-dateTime(), '[Y0001][M01][D01][H01][m01][s01][f01]')"/>
    
    <xsl:param name="location" select="."/> <!-- Replaced by ${cfdu} in Oxygen parameter configuration -->
    
    <xsl:param name="source" select="collection(concat($location, '?select=*-mods.xml'))"/>
    
    <!-- PACKET STRUCTURE -->
    
    <xsl:template name="container">
        <xsl:result-document indent="yes" encoding="UTF-8">
            <doi_batch version="4.3.7" xmlns="http://www.crossref.org/schema/4.3.7"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xsi:schemaLocation="http://www.crossref.org/schema/4.3.7 http://doi.crossref.org/schemas/crossref4.3.7.xsd">
                
                <xsl:call-template name="head"/>
                <xsl:call-template name="body"/>
                
            </doi_batch>
        </xsl:result-document>
    </xsl:template>
    
    <xsl:template name="head">
        <head>
            
            <!-- Unique IDs from timestamp -->
            <doi_batch_id><xsl:value-of select="$now"/></doi_batch_id>
            <timestamp><xsl:value-of select="$now"/></timestamp>
            
            <!-- Library info -->
            <depositor>
                <depositor_name>Dartmouth College Library</depositor_name>
                <email_address>Library.Catmet.Requests@Dartmouth.EDU</email_address>
            </depositor>
            <registrant>Dartmouth College Library</registrant>
            
        </head>
    </xsl:template>
    
    <xsl:template name="body">
        <body>
            <xsl:choose>
                
                <!-- Dissertations -->
                <xsl:when test="$source[1]/mods:mods/mods:genre[@authority='marcgt'] = 'thesis'">
                    <xsl:for-each select="$source/mods:mods[mods:extension/drb:flag[@type='doi']/@registered = '']">
                        <xsl:call-template name="dissertation"/>
                    </xsl:for-each>
                </xsl:when>
                
                <!-- Book set, as tested for Marcus Jewelry Drawings -->
                <xsl:when test="$source[1]/mods:mods/mods:genre[@authority='marcgt'] = 'art original'">
                    <xsl:for-each select="$source/mods:mods[mods:extension/drb:flag[@type='doi']/@registered = '']">
                        <xsl:call-template name="book-set"/>
                    </xsl:for-each>
                </xsl:when>
                
                <!-- Database/Dataset (full metadata required on update, so no need to check @registered) -->
                <xsl:otherwise>
                    <xsl:for-each-group select="$source/mods:mods"
                        group-by="mods:relatedItem[@type='host']/mods:titleInfo/mods:title">
                        <xsl:call-template name="database"/>
                    </xsl:for-each-group>
                </xsl:otherwise>
                
            </xsl:choose>
        </body>
    </xsl:template>
    
    <!-- CONTENT TYPES -->
    
    <xsl:template name="dissertation">
        <dissertation>
            
            <!-- Date part of author's name not included -->
            <person_name sequence="first" contributor_role="author">
                <given_name><xsl:value-of select="mods:name[@usage]/mods:namePart[@type='given']"/></given_name>
                <surname><xsl:value-of select="mods:name[@usage]/mods:namePart[@type='family']"/></surname>
                <xsl:for-each select="mods:name[@usage]/mods:namePart[@type='termsOfAddress']">
                    <suffix><xsl:value-of select="."/></suffix>
                </xsl:for-each>
            </person_name>
            
            <!-- Incorporates main title, subtitle, and non-sort -->
            <titles>
                <xsl:choose>
                    <xsl:when test="not(mods:titleInfo[not(@*)]/mods:subTitle)">
                        <title>
                            <xsl:value-of select="normalize-space(mods:titleInfo[not(@*)][child::*])"/>
                        </title>
                    </xsl:when>
                    <xsl:otherwise>
                        <title>
                            <xsl:value-of select="normalize-space(concat(mods:titleInfo[not(@*)]/mods:nonSort,
                                mods:titleInfo[not(@*)]/mods:title))"/>
                        </title>
                        <subtitle>
                            <xsl:value-of select="mods:titleInfo[not(@*)]/mods:subTitle"/>
                        </subtitle>
                    </xsl:otherwise>
                </xsl:choose>
            </titles>
            
            <approval_date>
                <year><xsl:value-of select="mods:originInfo/mods:dateIssued"/></year>
            </approval_date>
            
            <institution>
                <institution_name>Dartmouth College</institution_name>
            </institution>
            
            <degree>Ph.D.</degree>
            
            <doi_data>
                <doi><xsl:value-of select="substring-after(mods:identifier[@type='doi'], 'doi.org/')"/></doi>
                <resource><xsl:value-of select="mods:location/mods:url[@usage]"/></resource>
            </doi_data>
            
        </dissertation>
    </xsl:template>
    
    <xsl:template name="book-set">
        <book book_type="other">
            <book_set_metadata language="en">
                
                <!-- Collection-level data -->
                <set_metadata>
                    <titles>
                        <title>
                            <xsl:value-of select="normalize-space(mods:relatedItem[@type='host']/mods:titleInfo[child::*])"/>
                        </title>
                    </titles>
                    <noisbn reason="archive_volume"/>
                    <xsl:if test="position() = 1">
                        <doi_data>
                            <doi>
                                <xsl:value-of select="substring-after(mods:relatedItem[@type='host']/
                                    mods:identifier[@type='doi'], 'doi.org/')"/>
                            </doi>
                            <resource>
                                <xsl:value-of select="mods:relatedItem[@type='host']/mods:location/mods:url[@usage]"/>
                            </resource>
                        </doi_data>
                    </xsl:if>
                </set_metadata>
                
                <titles>
                    <title>
                        <xsl:value-of select="mods:titleInfo[not(@type)]/mods:title"/>
                    </title>
                </titles>
                <volume>
                    <xsl:value-of select="substring-after(mods:titleInfo[@type='uniform']/mods:partNumber, 'Volume ')"/>
                </volume>
                <publication_date media_type="print">
                    <year>
                        <xsl:value-of select="mods:relatedItem[@type='otherFormat']/mods:originInfo[@eventType='production']/
                            mods:dateCreated[@encoding='w3cdtf'][last()]"/>
                    </year>
                </publication_date>
                <publication_date media_type="online">
                    <year>
                        <xsl:value-of select="mods:originInfo[@eventType='publication']/*[@keyDate]"/>
                    </year>
                </publication_date>
                <noisbn reason="archive_volume"/>
                <publisher>
                    <publisher_name>
                        <xsl:value-of select="mods:originInfo[@eventType='publication']/mods:publisher"/>
                    </publisher_name>
                </publisher>
                
                <doi_data>
                    <doi>
                        <xsl:value-of select="substring-after(mods:identifier[@type='doi'], 'doi.org/')"/>
                    </doi>
                    <resource>
                        <xsl:value-of select="mods:location/mods:url[@usage]"/>
                    </resource>
                </doi_data>
                
            </book_set_metadata>
        </book>
    </xsl:template>
    
    <xsl:template name="database">
        <database>
            
            <database_metadata>
                <titles>
                    <title>
                        <xsl:value-of select="current-group()[1]/
                            normalize-space(mods:relatedItem[@type='host']/mods:titleInfo[child::*])"/>
                    </title>
                </titles>
                <doi_data>
                    <doi>
                        <xsl:value-of select="current-group()[1]/substring-after(mods:relatedItem[@type='host']/
                            mods:identifier[@type='doi'], 'doi.org/')"/>
                    </doi>
                    <resource>
                        <xsl:value-of select="current-group()[1]/mods:relatedItem[@type='host']/
                            mods:location/mods:url[@usage]"/>
                    </resource>
                </doi_data>   
            </database_metadata>
            
            <xsl:for-each select="current-group()">
                <xsl:call-template name="dataset"/>
            </xsl:for-each>
            
        </database>
    </xsl:template>
    
    <xsl:template name="dataset">
        <dataset>
            
            <titles>
                <xsl:for-each select="mods:titleInfo[1]">
                    <xsl:choose>
                        <xsl:when test="mods:subTitle">
                            <title>
                                <xsl:value-of select="normalize-space(concat(mods:nonSort, mods:title))"/>
                            </title>
                            <subtitle>
                                <xsl:value-of select="mods:subTitle"/>
                            </subtitle>
                        </xsl:when>
                        <xsl:otherwise>
                            <title>
                                <xsl:value-of select="normalize-space(child::*)"/>
                            </title>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </titles>
            
            <!--<titles>
                <xsl:choose>
                    <xsl:when test="not(mods:titleInfo[not(@*)]/mods:subTitle)">
                        <title>
                            <xsl:value-of select="normalize-space(mods:titleInfo[not(@*)][child::*])"/>
                        </title>
                    </xsl:when>
                    <xsl:otherwise>
                        <title>
                            <xsl:value-of select="normalize-space(concat(mods:titleInfo[not(@*)]/mods:nonSort,
                                mods:titleInfo[not(@*)]/mods:title))"/>
                        </title>
                        <subtitle>
                            <xsl:value-of select="mods:titleInfo[not(@*)]/mods:subTitle"/>
                        </subtitle>
                    </xsl:otherwise>
                </xsl:choose>
            </titles>-->
            
            <doi_data>
                <doi>
                    <xsl:value-of select="substring-after(mods:identifier[@type='doi'], 'doi.org/')"/>
                </doi>
                <resource>
                    <xsl:value-of select="mods:location/mods:url[@usage]"/>
                </resource>
            </doi_data>
            
        </dataset>
    </xsl:template>
    
</xsl:stylesheet>