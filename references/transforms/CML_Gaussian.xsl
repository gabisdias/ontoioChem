<!--

    Create module - Create module inside the ioChem-BD software.
    Copyright © 2014 ioChem-BD (contact@iochem-bd.org)

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

-->
<xsl:stylesheet 
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:cml="http://www.xml-cml.org/schema"
    xmlns:cmlx="http://www.xml-cml.org/schema/cmlx"
    xmlns:ckbk="http://my.safaribooksonline.com/book/xml/0596009747/numbers-and-math/77"
    xmlns:gaussian="http://www.gaussian.com/"
    xmlns:helper="http://www.w3.org/1999/XSL/Helper-Functions"
    
    xpath-default-namespace="http://www.xml-cml.org/schema" exclude-result-prefixes="xs xd cml ckbk gaussian helper cmlx"
    version="2.0">    
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Jun 12, 2024</xd:p>
            <xd:p><xd:b>Author:</xd:b>Moisés Álvarez Moreno and Diego Garay Ruiz</xd:p>
            <xd:p><xd:b>Center:</xd:b>Institute of Chemical Research of Catalonia</xd:p>            
        </xd:desc>     
    </xd:doc>
    <xsl:include href="gaussian_helper.xsl"/>
    <xsl:include href="chem_helper.xsl"/>
    <xsl:output method="text" omit-xml-declaration="yes" indent="no" />
    <xsl:strip-space elements="*"/>

    <xsl:param name="title"/>
    <xsl:param name="author"/>    

    <xsl:variable name="isOptimization" select="exists(//module[@cmlx:templateRef='l103']) and exists(//module[@dictRef='cc:initialization']/parameterList/parameter[@dictRef='g:keyword'][matches(., '[Oo][Pp][Tt](\s*=.*)?')])"/>
    <xsl:variable name="isFragmented" select="exists(//molecule//property[@dictRef='g:fragment'])" />
    <xsl:variable name="hasStationaryPoint" select="count(//module[@cmlx:templateRef='l103.optimizedparam']//scalar[@dictRef='g:optimization' and contains(text(),'Stationary point found')]) > 0"/>
    <xsl:variable name="hasMinimum" select="count(//module[@cmlx:templateRef='l103.localminsaddle']/scalar[@dictRef='cc:minmaxts' and contains(text(),'local minimum')])> 0"/>
    <xsl:variable name="isEET" select="count(//module[@id='initialization']/parameterList/parameter[@dictRef='g:keyword']/scalar[matches(lower-case(text()),'eet..*')]) > 0" />
    <xsl:variable name="calcType" select="gaussian:getCalcType($isOptimization,$hasStationaryPoint,$hasMinimum,$isEET)"/>  
    <xsl:variable name="methods">
        <xsl:for-each select="distinct-values(tokenize(string-join(//module[@dictRef='cc:initialization']/parameterList/parameter[@dictRef='cc:method']/scalar,' '), '[ /\(\):,]+'))">
            <xsl:variable name="candidate" select="."/>            
            <xsl:if test="gaussian:isMethod($candidate)">
                <xsl:value-of select="$candidate"/><xsl:text> </xsl:text>
            </xsl:if>            
        </xsl:for-each>            
    </xsl:variable>    
    
    <xsl:variable name="qmmModule" select="(//module[@cmlx:templateRef='l101.qmmm'])[1]"/>
    <xsl:variable name="zmatModule" select="//module[@cmlx:templateRef='l101.zmat']"/>
    <xsl:variable name="zmataModule" select="//module[@cmlx:templateRef='l101.zmata']"/>
    <xsl:variable name="charge" select="if((//module[@id='initialization']/molecule/@formalCharge)[1] != '') then
                                            (//module[@id='initialization']/molecule/@formalCharge)[1]
                                        else
                                            (//module[@dictRef='cc:finalization']//module[@cmlx:templateRef='l9999.archive']//list[@type='chargemult']//scalar[@dictRef='x:formalCharge'])[last()]                                            
                                        "/>
    <xsl:variable name="multiplicity" select="if((//module[@id='initialization']/molecule/@spinMultiplicity)[1] != '') then
                                                   (//module[@id='initialization']/molecule/@spinMultiplicity)[1]
                                              else
                                                   (//module[@dictRef='cc:finalization']//module[@cmlx:templateRef='l9999.archive']//list[@type='chargemult']//scalar[@dictRef='x:spinMultiplicity'])[last()]
                                              "/>  

    <xsl:variable name="modRedundant" select="//module[@cmlx:templateRef='l101.modredundant']"/>
    <xsl:variable name="pointGroup" select="(//module[@cmlx:templateRef='l202.stoich'])[last()]"/>
    <xsl:variable name="solvationModule" select="//module[@cmlx:templateRef='l301.pcm.standard']"/>
    
    <xsl:variable name="hasVibrations" select="exists(//module[@cmlx:templateRef='l716.freq.chunkx' and @dictRef='cc:vibrations'])"/>
    <!-- Environment module-->
    <xsl:variable name="programParameter" select="(//module[@id='job'][1]/module[@id='environment']/parameterList/parameter[@dictRef='cc:program']/scalar/text())[1]"/>
    <xsl:variable name="versionParameter" select="(//module[@id='job'][1]/module[@id='environment']/parameterList/parameter[@dictRef='cc:version']/scalar/text())[1]"/>
    <!-- Initialization module -->
    <xsl:variable name="initialMolecule" select="(//module[@dictRef='cc:initialization' and child::molecule])[1]/molecule"/>   
    <!-- Geometry -->
    <xsl:variable name="finalMolecule" select="(//module[@dictRef='cc:finalization' and child::molecule])[last()]//molecule[@id='mol9999']"/>
    <xsl:variable name="pseudopotentials" select="//module[@id='job']//module[@cmlx:templateRef='l301.basis2']/module[@cmlx:templateRef='pseudopot']/module[@cmlx:templateRef='atom']"/>
    <xsl:variable name="centers" select="//module[@id='job'][1]//module[@cmlx:templateRef='l301.basis2'][1]/module[@cmlx:templateRef='centers']"/>
    <xsl:variable name="centers2" select="distinct-values(//module[@id='initialization']/parameterList/parameter[@dictRef='cc:basis']/scalar)"/>
    <xsl:variable name="oniombasis" select="//module[@id='calculation']//module[@cmlx:templateRef='l120a']"/>    
    
    <!-- If exists SCAN calculations, check all YES on convergence table otherwise search for "Stationary point found" text-->
    <xsl:variable name="converged" select="
        if(exists(//module[@cmlx:templateRef='l101.modredundant'])) 
        then
            matches((//module[@cmlx:templateRef='l103.itemconverge'])[last()]/list/array[@dictRef='g:converged'],'^(YES\s*)+$')
        else
            exists(//scalar[@dictRef='g:optimization' and contains(text(),'Stationary point found')])
    "/>    
                                                       
    <xsl:variable name="quote">"</xsl:variable>
    <xsl:variable name="quote_escaped">\\"</xsl:variable>
    
    <xsl:variable name="singlequote">'</xsl:variable>
    <xsl:variable name="singlequote_escaped">\\'</xsl:variable>
    
    
    <xsl:template match="/">
                                 
        <xsl:variable name="molecule" select="
            if(exists($finalMolecule)) 
                then $finalMolecule
            else
                $initialMolecule
            "/>                                                             
                          
            <xsl:choose>
                <xsl:when test="$isFragmented">
                    <xsl:call-template name="atomicCoordinates">
                        <xsl:with-param name="molecule" select="$molecule"/>
                        <xsl:with-param name="centers"  select="$centers"/>                                                                                        
                        <xsl:with-param name="centers2" select="$centers2"/>
                        <xsl:with-param name="pseudos"  select="$pseudopotentials"/>
                        <xsl:with-param name="oniombasis" select="$oniombasis"/>
                    </xsl:call-template>                                    
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="atomicCoordinates">
                        <xsl:with-param name="molecule" select="$molecule"/>
                        <xsl:with-param name="centers"  select="$centers"/>                                                                                        
                        <xsl:with-param name="centers2" select="$centers2"/>
                        <xsl:with-param name="pseudos"  select="$pseudopotentials"/>
                        <xsl:with-param name="oniombasis" select="$oniombasis"/>
                    </xsl:call-template>    
                </xsl:otherwise>
            </xsl:choose>                                
                                
            <xsl:variable name="inchi" select="(.//cml:module[@dictRef='cc:finalization']/cml:molecule/cml:formula[@convention='iupac:inchi'])[1]/@inline"/>
            <xsl:value-of select="concat('inchi:',$inchi,'#;#')"/>
            <xsl:call-template name="chargemultiplicity"/>
            <xsl:call-template name="mcscf"/>
            <xsl:call-template name="frozenSection"/>
            <xsl:call-template name="pointgroupSection"/>
            <xsl:call-template name="solvatationSection"/>                            
            <xsl:text> GENERAL_END&#xa;</xsl:text>
            <xsl:for-each select="//module[@cmlx:templateRef='job']">
                <xsl:variable name="method" select=".//cml:parameter[@dictRef='cc:method']/cml:scalar"/>
                <xsl:variable name="basisset" select=".//cml:parameter[@dictRef='cc:basis'][1]/cml:scalar"/>
                <xsl:value-of select="concat('method: ',string-join($method),'#;#')"/>
                <xsl:value-of select="concat('basis: ',string-join($basisset),'#;#')"/>
                <xsl:variable name="jobMolecule" select="(.//module[@dictRef='cc:initialization' and child::molecule])/molecule"/>  
                <xsl-text>initialCoordinates:</xsl-text>
                <xsl:call-template name="getCoordinates">
                    <xsl:with-param name="molecule" select="$jobMolecule"></xsl:with-param>
                </xsl:call-template>
                <xsl-text>#;#</xsl-text>
                
                <xsl:choose>
                    <xsl:when test="not($isFragmented)">
                        <xsl:call-template name="energiesSection"/>        
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="energiesFragmentedSection"/>
                    </xsl:otherwise>
                </xsl:choose>

                <xsl:call-template name="spinSection" />  
                <xsl:call-template name="frequencies"/>
                <xsl:call-template name="espcharges"/>
                <xsl:call-template name="mullikenCharges"/>
                <xsl:call-template name="dipoleMoment"/>
                <xsl:variable name="thermoSection" select=".//module[@id='finalization']/propertyList/property[@dictRef='cc:thermochemistry']/list[@id='l716.thermochemistry']"/>
                <xsl:if test="exists($thermoSection)">
                    <xsl:call-template name="thermoParameters">
                        <xsl:with-param name="thermoSection" select="$thermoSection"/>
                    </xsl:call-template>
                </xsl:if>
                <xsl:text> FETCH_JOB_END&#xa;</xsl:text>                                                      
            </xsl:for-each>
                           
    </xsl:template>



    <!-- Atomic coordinates -->
    <xsl:template name="getCoordinates">
        <xsl:param name="molecule"/>
        <xsl:for-each select="$molecule/atomArray/atom">
            <xsl:variable name="outerIndex" select="position()"/>
            <xsl:variable name="elementType" select="@elementType"/>
            <xsl:value-of select="concat($elementType,' ',format-number(@x3, '#0.0000'),' ',format-number(@y3, '#0.0000'),' ',format-number(@z3, '#0.0000'),'&#xa;')"/>
        </xsl:for-each>
    </xsl:template>
    <xsl:template name="atomicCoordinates">
        <xsl:param name="molecule"/>
        <xsl:param name="centers"/>
        <xsl:param name="centers2"/>
        <xsl:param name="pseudos"/>
        <xsl:param name="oniombasis"/>
        <xsl:variable name="collapseAccordion" select="if(count($molecule/atomArray/atom) > 10) then '' else 'in'"/>
        <xsl:variable name="isLargeMolecule" select="count($molecule/atomArray/atom) > 500"/>
        
        <xsl:if test="contains($calcType,$gaussian:GeometryOptimization)">
            <xsl:choose>
                <xsl:when test="boolean($converged)">
                    <xsl-text>optConvergeStatus:True#;#</xsl-text>       
                </xsl:when>
                <xsl:otherwise>      
                    <xsl-text>optConvergeStatus:False#;#</xsl-text>
                </xsl:otherwise>
            </xsl:choose>                                                           
        </xsl:if>                    
        
        <xsl-text>geometryCartesian:</xsl-text>
        <xsl:for-each select="$molecule/atomArray/atom">
            <xsl:variable name="outerIndex" select="position()"/>
            <xsl:variable name="elementType" select="@elementType"/>
            <xsl:value-of select="concat($elementType,' ',format-number(@x3, '#0.0000'),' ',format-number(@y3, '#0.0000'),' ',format-number(@z3, '#0.0000'),'&#xa;')"/>
        </xsl:for-each>
        <xsl-text>#;#</xsl-text>
        
        <xsl:value-of select="concat('basisPerAtom:index atom type', '&#xa;')"/>
        <xsl:for-each select="$molecule/atomArray/atom">
            <xsl:variable name="outerIndex" select="position()"/>
            <xsl:variable name="id" select="@id"/>
            <xsl:variable name="elementType" select="@elementType"/>
            <xsl:variable name="type">
                <xsl:choose>
                    <xsl:when test="exists($centers)">
                        <xsl:for-each select="$centers">
                            <xsl:variable name="basis" select="./scalar[@dictRef='cc:basis']"/>
                            <xsl:for-each select="tokenize(./array[@dictRef='cc:atomcount'],'(\s|\n)')">
                                <xsl:if test=".=string($outerIndex)">
                                    <xsl:value-of select="concat($outerIndex,' ',$elementType,' ',$basis,'&#xa;')"/>
                                </xsl:if>
                            </xsl:for-each>
                        </xsl:for-each>
                    </xsl:when>
                        <xsl:when test="exists($oniombasis)">
                            <xsl:variable name="level" select="(//module[@cmlx:templateRef='l101.qmmm'])[1]/list[@cmlx:templateRef='isotope'][$outerIndex]/scalar[@dictRef='x:layer']"/>
                            <xsl:choose>
                                <xsl:when test="$level = 'H'"><xsl:value-of select="concat('oniomBasisHigh:',$oniombasis[child::scalar[@dictRef='x:level']/text() = 'high']/scalar[@dictRef='cc:basis'],'#;#')"/></xsl:when>
                                <xsl:when test="$level = 'M'"><xsl:value-of select="concat('oniomBasisMed:',$oniombasis[child::scalar[@dictRef='x:level']/text() = 'med']/scalar[@dictRef='cc:basis'],'#;#')"/></xsl:when>
                                <xsl:when test="$level = 'L'"><xsl:value-of select="concat('oniomBasisLow:',$oniombasis[child::scalar[@dictRef='x:level']/text() = 'low']/scalar[@dictRef='cc:basis'],'#;#')"/></xsl:when>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:variable name="joinedCenters2" select="string-join($centers2,' ')"/>
                            <xsl:value-of select="concat($outerIndex,' ',$elementType,' ',$joinedCenters2,'&#xa;')"/>
                        </xsl:otherwise>
                </xsl:choose>
            </xsl:variable> 
            
<!--            <xsl:value-of select="concat('basisSet:',distinct-values($type),'#;#')"/>-->
            <xsl:value-of select="$type"/>
            <!-- Core information (omitted)-->
<!--            <xsl:variable name="core">
                <xsl:for-each select="$centers">                                           
                    <xsl:variable name="shell" select="./list[@cmlx:templateRef='shell']"/>                                                        
                    <xsl:for-each select="tokenize(./array[@dictRef='cc:atomcount'],'(\s|\n)')">                               
                        <xsl:if test=".=string($outerIndex) and count($shell) > 0">                                                
                            <xsl:for-each select="$shell">
                                <xsl:variable name="currentShell" select="."/>
                                <xsl:variable name="exponents" select="replace($currentShell/array[@dictRef='x:exponent'],'(\s+|\n+)',',')"/>
                                <xsl:variable name="coefficients" select="replace($currentShell/array[@dictRef='x:coeficient'],'(\s+|\n+)',',')"/>                                                        
                                <xsl:value-of select="$currentShell/scalar[@dictRef='x:itype']"/>
                                <xsl:value-of select="$currentShell/scalar[@dictRef='x:ngauss']"/>
                                <xsl:text> </xsl:text>
                                <xsl:value-of select="$currentShell/scalar[@dictRef='x:scale']"/>                                                 
                                <xsl:value-of select="$exponents"/>],[<xsl:value-of select="$coefficients"/>                                                                                             
                            </xsl:for-each>                                            
                        </xsl:if>                                    
                    </xsl:for-each>                                            
                </xsl:for-each>                                                                                                                                                       
            </xsl:variable>        -->            
            
<!--            <!-\- Pseudopotentials information -\->                                        
            <xsl:variable name="pseudo" select="$pseudos[child::scalar[@dictRef='cc:serial'] = $outerIndex]"/>
            <xsl:variable name="pseudolines">
                <xsl:choose>
                    <xsl:when test="not(exists($pseudo/scalar[@dictRef='cc:nopseudo']))">
                        <xsl:value-of select="concat('pseudoPotentialParams',position(),':angMomentum,powerR,basisExp,expCoeff,SOCoeff &#xa;')"/>
                        <xsl:for-each select="$pseudo//module[@cmlx:templateRef='params']">                                                   
                            <xsl:variable name="angmomentum" select=".//scalar[@dictRef='cc:angmomentum']"/>
                            <xsl:variable name="powerofr" select="tokenize(.//array[@dictRef='g:powerofr'],'\s+')"/>
                            <xsl:variable name="basisexponent" select="tokenize(.//array[@dictRef='cc:basisexponent'],'\s+')"/>
                            <xsl:variable name="expcoeff" select="tokenize(.//array[@dictRef='cc:expcoeff'],'\s+')"/>
                            <xsl:variable name="socoeff" select="tokenize(.//array[@dictRef='g:socoeff'],'\s+')"/>                            
                            <xsl:for-each select="1 to count($powerofr)">        
                                <xsl:variable name="innerIndex" select="."/>
                                <xsl:value-of select="concat($angmomentum,' ')"/>
                                <xsl:value-of select="concat($powerofr[$innerIndex],' ')"/>
                                <xsl:value-of select="concat($basisexponent[$innerIndex],' ')"/>
                                <xsl:value-of select="concat($expcoeff[$innerIndex],' ')"/>
                                <xsl:value-of select="concat($socoeff[$innerIndex],'&#xa;')"/>                                                                                                              
                            </xsl:for-each>
                            <xsl-text>#;#</xsl-text>
                        </xsl:for-each>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl-text>pseudoPotentialParams:None#;#</xsl-text>
                    </xsl:otherwise>
                </xsl:choose>                                                
            </xsl:variable>-->
<!--            <xsl:value-of select="$outerIndex"/>
            <xsl:value-of select="$elementType"/>'
            <xsl:value-of select="format-number(@x3,'#0.0000')"/>
            <xsl:value-of select="format-number(@y3,'#0.0000')"/>
            <xsl:value-of select="format-number(@z3,'#0.0000')"/>
            <xsl:value-of select="distinct-values($type)"/>
            <xsl:choose>
                <xsl:when test="matches($core,'^\s*$')">','</xsl:when>
                <xsl:otherwise>
                    <span class="fa fa-plus"/>   
                    <xsl:value-of select="$core"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
                <xsl:when test="not(exists($pseudo)) or exists($pseudo/scalar[@dictRef='cc:nopseudo'])">','</xsl:when>
                <xsl:otherwise>
                    <span class="fa fa-plus"/>
                    <xsl:value-of select="$pseudolines"/>
                </xsl:otherwise></xsl:choose>-->
        </xsl:for-each>
        <xsl:value-of select="'#;#'"/>
        
        <!--],
                                        
                                        "aoColumns": [
                                            { "sTitle": "ATOM" },
                                            { "sTitle": "" },
                                            { "sTitle": "x", "sClass": "right" },
                                            { "sTitle": "y", "sClass": "right" },
                                            { "sTitle": "z", "sClass": "right" },
                                            { "sTitle": "TYPE", "sClass" : "nowrap" },
                                            { "sTitle": "Core" },                                
                                            { "sTitle": "Core" },
                                            { "sTitle": "ECP"  }, 
                                            { "sTitle": "ECP"  }
                                        ],
                                        "aoColumnDefs" : [
                                            { "bVisible": false, "aTargets": [ 7 ] },
                                            { "bVisible": false, "aTargets": [ 9 ]  }                                
                                        ],
                                        "bFilter": false,
                                        "bPaginate": false,
                                        "bSort": false,
                                        "bInfo": false
                                        });
                                        
                                        function fnFormatCoreECP ( nTr )
                                        {                                
                                            var aData = oTable.fnGetData( nTr );                                
                                            var sOut = '';
                                            if(aData[7].length > 0){
                                            sOut +='<table cellpadding="5" cellspacing="0" border="0" style="padding-left:50px;">'; 
                                                for(var i=0; i&lt; aData[7].length; i++) {                                    
                                                sOut += '<tr><td>' + aData[7][i][0] + '</td><td>' + aData[7][i][1] + '</td><td></td></tr>';
                                                for(var j=0; j &lt; aData[7][i][2].length; j++)
                                                sOut += '<tr><td></td><td class="nowrap">Exponent =' + aData[7][i][2][j] + '</td><td class="nowrap">Coefficients = ' + aData[7][i][3][j] + '</td></tr>';    
                                                }
                                                sOut += '</table>';
                                            }
                                            if(aData[9].length > 0){
                                            sOut += '<table cellpadding="5" cellspacing="0" border="0" style="padding-left:50px;">';
                                                sOut += '<tr><td>Angular Momentum</td><td>Power of R</td><td>Exponent</td><td>Coefficient</td><td>SO-Coeffient</td></tr>';
                                                for(var i=0; i&lt; aData[9].length; i++) {
                                                sOut += '<tr><td>' + aData[9][i][0] + '</td><td class="right">' + aData[9][i][1] + '</td><td class="right">' + aData[9][i][2] + '</td><td class="right">' + aData[9][i][3] + '</td><td class="right">' + aData[9][i][4] + '</td></tr>';    
                                                }
                                                sOut += '</table>';                                         
                                            }
                                            return sOut;
                                        }
                                        
                                        $('#atomicCoordinates tbody tr td span.fa-plus , #atomicCoordinates tbody tr td span.fa-minus').on( 'click', function () {
                                            var nTr = $(this).parents('tr')[0];
                                            if ( oTable.fnIsOpen(nTr) ){
                                                /* This row is already open - close it */
                                                $(this).toggleClass("fa-plus fa-minus");
                                                oTable.fnClose( nTr );
                                            } else {
                                                /* Open this row */
                                                $(this).toggleClass("fa-plus fa-minus");
                                                oTable.fnOpen( nTr, fnFormatCoreECP(nTr), 'details' );
                                            }
                                        });                                        
                                        });
                                    </script>
                                </xsl:when>
                                <xsl:otherwise>
                                    <script type="text/javascript">
                                        $(document).ready(function() {
                                            oTable = $('table#atomicCoordinates').dataTable({
                                                "aaData": atomInfo,
                                                "aoColumns": [
                                                    { "sTitle": "ATOM" },
                                                    { "sTitle": "" },
                                                    { "sTitle": "x", "sClass": "right" },
                                                    { "sTitle": "y", "sClass": "right" },
                                                    { "sTitle": "z", "sClass": "right" }
                                                ],
                                                "bFilter": false,
                                                "bPaginate": false,
                                                "bSort": false,
                                                "bInfo": false
                                            });                       
                                        });
                                    </script>                                    
                                </xsl:otherwise>
                            </xsl:choose>

                            <table class="display" id="atomicCoordinates"></table>                                                                              
                        </div>
                    </div>
                </div>
            </div>
        </div> -->
    </xsl:template>
    
    
    <!-- Atomic coordinates -->
    <xsl:template name="atomicCoordinatesWithFragments">
        <xsl:param name="molecule"/>
        <xsl:param name="centers"/>
        <xsl:param name="centers2"/>
        <xsl:param name="pseudos"/>
        <xsl:param name="oniombasis"/>

        <xsl:if test="contains($calcType,$gaussian:GeometryOptimization)">
            <xsl:choose>
                <xsl:when test="boolean($converged)">
                    <xsl-text>optConvergeStatus:True#;#</xsl-text>       
                </xsl:when>
                <xsl:otherwise>      
                    <xsl-text>optConvergeStatus:False#;#</xsl-text>
                </xsl:otherwise>
            </xsl:choose>                                                           
        </xsl:if>                    

        <xsl-text>geometryCartesian:</xsl-text>
        <xsl:for-each select="$molecule/atomArray/atom">
            <xsl:variable name="outerIndex" select="position()"/>
            <xsl:variable name="elementType" select="@elementType"/>
            <xsl:value-of select="$outerIndex"/>
            <xsl:value-of select="$elementType"/>'
            <xsl:value-of select="concat($elementType,' ',format-number(@x3, '#0.0000'),' ',format-number(@y3, '#0.0000'),' ',format-number(@z3, '#0.0000'),'&#xa;')"/>
        </xsl:for-each>
        <xsl-text>#;#</xsl-text>
        <xsl-text>fragmentMapping:</xsl-text>
        <xsl:for-each select="$molecule/atomArray/atom">
            <xsl:variable name="outerIndex" select="position()"/>
            <xsl:variable name="elementType" select="@elementType"/>
            <xsl:variable name="fragIndex" select="./property[@dictRef='g:fragment']/scalar"/>
            <xsl:value-of select="concat($outerIndex,' ',$fragIndex, '&#xa;')"/>
        </xsl:for-each>
        <xsl-text>#;#</xsl-text>
                   
<!--       <!-\-        Centers and ONIOM basis-\->
       <xsl:for-each select="$molecule/atomArray/atom">
           <xsl:variable name="outerIndex" select="position()"/>
           <xsl:variable name="id" select="@id"/>
           <xsl:variable name="elementType" select="@elementType"/>
           <xsl:variable name="fragment" select="./property[@dictRef='g:fragment']" />
           <xsl:variable name="type">
               <xsl:choose>
                   <xsl:when test="exists($centers)">
                       <xsl:for-each select="$centers">
                           <xsl:variable name="basis" select="./scalar[@dictRef='cc:basis']"/>
                           <xsl:for-each select="tokenize(./array[@dictRef='cc:atomcount'],'(\s|\n)')">
                               <xsl:if test=".=string($outerIndex)">
                                   <xsl:value-of select="$basis"/><xsl:text>  </xsl:text>
                               </xsl:if>
                           </xsl:for-each>
                       </xsl:for-each>
                   </xsl:when>
                   <xsl:when test="exists($oniombasis)">
                       <xsl:variable name="level" select="(//module[@cmlx:templateRef='l101.qmmm'])[1]/list[@cmlx:templateRef='isotope'][$outerIndex]/scalar[@dictRef='x:layer']"/>
                       <xsl:choose>
                           <xsl:when test="$level = 'H'"><xsl:value-of select="$oniombasis[child::scalar[@dictRef='x:level']/text() = 'high']/scalar[@dictRef='cc:basis']"/></xsl:when>
                           <xsl:when test="$level = 'M'"><xsl:value-of select="$oniombasis[child::scalar[@dictRef='x:level']/text() = 'med']/scalar[@dictRef='cc:basis']"/></xsl:when>
                           <xsl:when test="$level = 'L'"><xsl:value-of select="$oniombasis[child::scalar[@dictRef='x:level']/text() = 'low']/scalar[@dictRef='cc:basis']"/></xsl:when>
                       </xsl:choose>
                   </xsl:when>
                   <xsl:otherwise>
                       <xsl:value-of select="$centers2"/>
                   </xsl:otherwise>
               </xsl:choose>
           </xsl:variable> 
           <!-\- Core information -\->
           <xsl:variable name="core">
               <xsl:for-each select="$centers">                                           
                   <xsl:variable name="shell" select="./list[@cmlx:templateRef='shell']"/>                                                        
                   <xsl:for-each select="tokenize(./array[@dictRef='cc:atomcount'],'(\s|\n)')">                               
                       <xsl:if test=".=string($outerIndex) and count($shell) > 0">       
                           <xsl-text>basisSetFullInfo:</xsl-text>
                           <xsl:for-each select="$shell">
                               <xsl:variable name="currentShell" select="."/>
                               <xsl:variable name="exponents" select="replace($currentShell/array[@dictRef='x:exponent'],'(\s+|\n+)',',')"/>
                               <xsl:variable name="coefficients" select="replace($currentShell/array[@dictRef='x:coeficient'],'(\s+|\n+)',',')"/>                                                        
                               <xsl:value-of select="$currentShell/scalar[@dictRef='x:itype']"/>
                               <xsl:value-of select="$currentShell/scalar[@dictRef='x:ngauss']"/><xsl:text> </xsl:text><xsl:value-of select="$currentShell/scalar[@dictRef='x:scale']"/>                                                 
                               <xsl:value-of select="$exponents"/>],[<xsl:value-of select="$coefficients"/>                                                                                                                   
                           </xsl:for-each>                                            
                       </xsl:if>                                    
                   </xsl:for-each>                                            
               </xsl:for-each>                                                                                                                                                       
           </xsl:variable>                                            
           <!-\- Pseudopotentials information -\->                                        
           <xsl:variable name="pseudo" select="$pseudos[child::scalar[@dictRef='cc:serial'] = $outerIndex]"/>
           <xsl:variable name="pseudolines">
               <xsl:choose>
                   <xsl:when test="not(exists($pseudo/scalar[@dictRef='cc:nopseudo']))">                                              
                       [<xsl:for-each select="$pseudo//module[@cmlx:templateRef='params']">                                                   
                           <xsl:variable name="angmomentum" select=".//scalar[@dictRef='cc:angmomentum']"/>
                           <xsl:variable name="powerofr" select="tokenize(.//array[@dictRef='g:powerofr'],'\s+')"/>
                           <xsl:variable name="basisexponent" select="tokenize(.//array[@dictRef='cc:basisexponent'],'\s+')"/>
                           <xsl:variable name="expcoeff" select="tokenize(.//array[@dictRef='cc:expcoeff'],'\s+')"/>
                           <xsl:variable name="socoeff" select="tokenize(.//array[@dictRef='g:socoeff'],'\s+')"/>
                           <xsl:for-each select="1 to count($powerofr)">
                               <xsl:variable name="innerIndex" select="."/>["<xsl:value-of select="$angmomentum"/>","<xsl:value-of select="$powerofr[$innerIndex]"/>","<xsl:value-of select="$basisexponent[$innerIndex]"/>","<xsl:value-of select="$expcoeff[$innerIndex]"/>","<xsl:value-of select="$socoeff[$innerIndex]"/>"],                                                                                                              
                           </xsl:for-each>                                                                                                        
                       </xsl:for-each>]
                   </xsl:when>
                   <xsl:otherwise>'',''</xsl:otherwise>
               </xsl:choose>                                                
           </xsl:variable>
           [<xsl:value-of select="$outerIndex" />,'<xsl:value-of select="$elementType"/>',<xsl:value-of select="$fragment"/>,'<xsl:value-of select="format-number(@x3,'#0.0000')"/>','<xsl:value-of select="format-number(@y3,'#0.0000')"/>','<xsl:value-of select="format-number(@z3,'#0.0000')"/>','<xsl:value-of select="distinct-values($type)"/>',<xsl:choose><xsl:when test="matches($core,'^\s*$')">'','',</xsl:when><xsl:otherwise>'<span class="fa fa-plus"/>',[<xsl:value-of select="$core"/>],</xsl:otherwise></xsl:choose><xsl:choose><xsl:when test="not(exists($pseudo)) or exists($pseudo/scalar[@dictRef='cc:nopseudo'])">'',''</xsl:when><xsl:otherwise>'<span class="fa fa-plus"/>',<xsl:value-of select="$pseudolines"/></xsl:otherwise></xsl:choose>]<xsl:if test="(position() &lt; count($molecule/atomArray/atom))"><xsl:text>,</xsl:text></xsl:if>
       </xsl:for-each>                                        
                                               ],
                                           
                                               "aoColumns": [
                                                   { "sTitle": "ATOM" },
                                                   { "sTitle": "" },
                                                   { "sTitle": "Fragment" },
                                                   { "sTitle": "x", "sClass": "right" },
                                                   { "sTitle": "y", "sClass": "right" },
                                                   { "sTitle": "z", "sClass": "right" },
                                                   { "sTitle": "TYPE", "sClass" : "nowrap" },
                                                   { "sTitle": "Core" },                                
                                                   { "sTitle": "Core" },
                                                   { "sTitle": "ECP"  }, 
                                                   { "sTitle": "ECP"  }
                                               ],
                                               "aoColumnDefs" : [
                                                   { "bVisible": false, "aTargets": [ 7 ] },
                                                   { "bVisible": false, "aTargets": [ 9 ]  }                                
                                               ],
                                               "bFilter": true,
                                               "bPaginate": false,
                                               "bSort": false,
                                               "bInfo": false
                                           });
                                           
                                           // Hide search box, use fragment selector instead
                                           $('#atomicCoordinates_filter').hide()
                                        
                                        function fnFormatCoreECP ( nTr ){                                
                                            var aData = coordsTable.fnGetData( nTr );                                
                                            var sOut = '';
                                            if(aData[7].length > 0) {
                                                sOut +='<table cellpadding="5" cellspacing="0" border="0" style="padding-left:50px;">'; 
                                                for(var i=0; i&lt; aData[7].length; i++) {                                    
                                                    sOut += '<tr><td>' + aData[7][i][0] + '</td><td>' + aData[7][i][1] + '</td><td></td></tr>';
                                                    for(var j=0; j &lt; aData[7][i][2].length; j++)
                                                        sOut += '<tr><td></td><td class="nowrap">Exponent =' + aData[7][i][2][j] + '</td><td class="nowrap">Coefficients = ' + aData[7][i][3][j] + '</td></tr>';    
                                                }
                                                sOut += '</table>';
                                            }
                                            if(aData[9].length > 0) {
                                                sOut += '<table cellpadding="5" cellspacing="0" border="0" style="padding-left:50px;">';
                                                sOut += '<tr><td>Angular Momentum</td><td>Power of R</td><td>Exponent</td><td>Coefficient</td><td>SO-Coeffient</td></tr>';
                                                for(var i=0; i&lt; aData[9].length; i++) {
                                                    sOut += '<tr><td>' + aData[9][i][0] + '</td><td class="right">' + aData[9][i][1] + '</td><td class="right">' + aData[9][i][2] + '</td><td class="right">' + aData[9][i][3] + '</td><td class="right">' + aData[9][i][4] + '</td></tr>';    
                                                }
                                                sOut += '</table>';                                         
                                            }
                                            return sOut;
                                        }
                                        
                                        $('#atomicCoordinates tbody tr td span.fa-plus , #atomicCoordinates tbody tr td span.fa-minus').on( 'click', function () {
                                            var nTr = $(this).parents('tr')[0];
                                            if ( coordsTable.fnIsOpen(nTr) ) {                                                
                                                $(this).toggleClass("fa-plus fa-minus");
                                                coordsTable.fnClose( nTr );
                                            } else {                                                
                                                $(this).toggleClass("fa-plus fa-minus");
                                                coordsTable.fnOpen( nTr, fnFormatCoreECP(nTr), 'details' );
                                            }
                                        });                                        
                                     });
                                    </script>
                                </xsl:when>
                                <xsl:otherwise>
                                    <script type="text/javascript">
                                        $(document).ready(function() {
                                            coordsTable = $('table#atomicCoordinates').dataTable({
                                                "aaData": atomInfo.map((val) => val.slice(1,6)),
                                                "aoColumns": [
                                                    { "sTitle": "ATOM" },
                                                    { "sTitle": "" },
                                                    { "sTitle": "x", "sClass": "right" },
                                                    { "sTitle": "y", "sClass": "right" },
                                                    { "sTitle": "z", "sClass": "right" }
                                                    ],
                                                "bFilter": false,
                                                "bPaginate": false,
                                                "bSort": false,
                                                "bInfo": false
                                            });                       
                                        });
                                    </script>                                    
                                </xsl:otherwise>
                            </xsl:choose>
                            
                            <table class="display" id="atomicCoordinates"></table>                                                                              
                        </div>
                    </div>
                </div>
            </div>
        </div> -->
    </xsl:template>
    
    

    <!-- Charge / Multiplicity section -->
    <xsl:template name="chargemultiplicity">

        <xsl:choose>                                            
            <xsl:when test="exists($qmmModule)">
                <xsl:variable name="charge" select="tokenize($qmmModule//array[@dictRef='g:charge'],'[\s]')"/>
                <xsl:variable name="multiplicity" select="tokenize($qmmModule//array[@dictRef='g:multiplicity'],'[\s]')"/>
                <xsl-text>chargesQMMM:</xsl-text>
                <xsl:for-each select="1 to count($charge)">
                    <xsl:variable name="outerIndex" select="."/>
                    <xsl:value-of select="concat($charge[$outerIndex],' ')"></xsl:value-of>
                </xsl:for-each>     
                <xsl-text>#;#</xsl-text>
                <xsl-text>multiplicitiesQMMM:</xsl-text>
                <xsl:for-each select="1 to count($charge)">
                    <xsl:variable name="outerIndex" select="."/>
                    <xsl:value-of select="concat($multiplicity[$outerIndex], ' ')"></xsl:value-of>
                </xsl:for-each>  
                <xsl-text>#;#</xsl-text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="exists($zmatModule/molecule)">
                        <xsl:value-of select="concat('charge:',$zmatModule/molecule/@formalCharge,'#;#')"/>
                        <xsl:value-of select="concat('multiplicity:',$zmatModule/molecule/@spinMultiplicity,'#;#')"/>
                    </xsl:when>
                    <xsl:when test="exists($zmataModule)">
                        <xsl:value-of select="concat('charge:',$zmataModule//scalar[@dictRef='x:formalCharge'],'#;#')"/>
                        <xsl:value-of select="concat('multiplicity:',$zmataModule//scalar[@dictRef='x:multiplicity'],'#;#')"/>                                            
                    </xsl:when>                                        
                    <xsl:otherwise>                                                    
                        <xsl:value-of select="concat('charge:',$charge,'#;#')"/>
                        <xsl:value-of select="concat('multiplicity:',$multiplicity,'#;#')"/>                                                                                                                                   
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>      
                        
        <xsl:if test="$isFragmented and exists(//module[@cmlx:templateRef='l101.zmatfragment'])">
            <xsl:variable name="fragCharge" select="tokenize(//module[@cmlx:templateRef='l101.zmatfragment']//array[@dictRef='g:charge'],'\s+')"/>
            <xsl:variable name="fragMult" select="tokenize(//module[@cmlx:templateRef='l101.zmatfragment']//array[@dictRef='g:mult'],'\s+')"/>
            <xsl:variable name="fragment" select="tokenize(//module[@cmlx:templateRef='l101.zmatfragment']//array[@dictRef='g:fragment'],'\s+')"/>
            <xsl-text>fragmentCharges:</xsl-text>
            <xsl:for-each select="1 to count($fragment)">
                <xsl:variable name="outerIndex" select="."/>
                    <xsl:value-of select="concat($fragCharge[$outerIndex],' ')"/> 
                <xsl-text>#;#</xsl-text>
            </xsl:for-each>         
            <xsl-text>fragmentMultiplicities:</xsl-text>
            <xsl:for-each select="1 to count($fragment)">
                <xsl:variable name="outerIndex" select="."/>
                <xsl:value-of select="concat($fragMult[$outerIndex],' ')"/> 
                <xsl-text>#;#</xsl-text>
            </xsl:for-each>  
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="mcscf">
        <xsl:variable name="mcscf" select="//module[@id='calculation']//module[@cmlx:templateRef='l405']"/>
        <xsl:if test="exists($mcscf)">
            <xsl:value-of select="concat('numOrbitals:',$mcscf/scalar[@dictRef='g:orbitalnum'],'#;#')"/>
            <xsl:value-of select="concat('numElectrons:',$mcscf/scalar[@dictRef='g:electronnum'],'#;#')"/>
        </xsl:if>
    </xsl:template>
    
    <!-- Frozen section (module) -->
    <xsl:template name="frozenSection">        
        <xsl:if test="exists($modRedundant)">
         
            <xsl-text>frozenSection: restriction idx action params &#xa;</xsl-text>
            <xsl:for-each select="$modRedundant/list[@cmlx:templateRef='modred']">
                <xsl:variable name="currentRestriction" select="."/>
                <xsl:variable name="parameter">
                    <xsl:choose>
                        <xsl:when test="exists($currentRestriction/scalar[@dictRef='x:parameter'])">
                            <xsl:value-of select="concat($currentRestriction/scalar[@dictRef='x:parameter'],' ')"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="concat($currentRestriction/scalar[@dictRef='x:stepnumber'],' ',$currentRestriction/scalar[@dictRef='x:stepincrement'])"/>
                        </xsl:otherwise>
                    </xsl:choose>                                            
                </xsl:variable>                                        
                <xsl:value-of select="$currentRestriction/scalar[@dictRef='x:restriction']"/>
                <xsl-text> </xsl-text>
                <xsl:value-of select="$currentRestriction/array[@dictRef='x:serial']"/>
                <xsl-text> </xsl-text>
                <xsl:value-of select="$currentRestriction/scalar[@dictRef='x:action']"/>
                <xsl-text> </xsl-text>
                <xsl:value-of select="$parameter"></xsl:value-of>
                <xsl-text>&#xa;</xsl-text>
            </xsl:for-each>
            <xsl-text>#;#</xsl-text>
        </xsl:if> 
    </xsl:template>
    
    <!-- Point group section (module) -->
    <xsl:template name="pointgroupSection">
        <xsl:if test="exists($pointGroup)">
            <xsl:variable name="currentModule" select="($pointGroup)[1]"></xsl:variable>            
                 <xsl:value-of select="concat('pointGroup:',$currentModule/scalar[@dictRef='cc:pointgroup'],'#;#')"/>
                 <xsl:value-of select="concat('numSymmOps:',($currentModule/scalar[@dictRef='cc:pointgroup']/following-sibling::scalar[@dictRef='cc:operatorcount'])[1],'#;#')"/>       
        </xsl:if>        
    </xsl:template>
    
    <!-- Solvatation section (module) -->
    <xsl:template name="solvatationSection">        
        <xsl:if test="exists($solvationModule)">
            <xsl:variable name="currentModule" select="($solvationModule)[1]"/>            
            <xsl-text>solvationModel:</xsl-text>
            <xsl:value-of select="$currentModule/scalar[@dictRef='g:model']"/>            
            <xsl-text>#;#</xsl-text>
            <xsl-text>solvationAtomRadii:</xsl-text>
            <xsl:value-of select="$currentModule/scalar[@dictRef='g:atomicradii']"/>       
            <xsl-text>#;#</xsl-text>
            <xsl-text>solvent:</xsl-text>
            <xsl:value-of select="$currentModule/scalar[@dictRef='g:solvent']"/>               
            <xsl-text>#;#</xsl-text>
            <xsl-text>solventEps:</xsl-text>
            <xsl:value-of select="$currentModule/scalar[@dictRef='g:eps']"/>        
            <xsl-text>#;#</xsl-text>
            <xsl-text>solventEpsInf:</xsl-text>
            <xsl:value-of select="$currentModule/scalar[@dictRef='g:epsinfinity']"/>
            <xsl-text>#;#</xsl-text>
        </xsl:if>        
    </xsl:template>
 
    <xsl:template name="thermoParameters">
        <xsl:param name="thermoSection"/>
        
        <xsl:variable name="temperature" select="$thermoSection/scalar[@dictRef='cc:temp']"/>
        <xsl:variable name="temperatureUnits" select="$thermoSection/scalar[@dictRef='cc:temp']/@units"/>
        <xsl:variable name="pressure" select="$thermoSection/scalar[@dictRef='cc:press']"/>
        <xsl:variable name="pressureUnits" select="$thermoSection/scalar[@dictRef='cc:press']/@units"/>
        <xsl:variable name="symmnumb" select="$thermoSection/cml:scalar[@dictRef='cc:symmnumber']"/>
        <xsl:variable name="rottemp" select="$thermoSection/cml:array[@dictRef='cc:rottemp']"/>
        <xsl:variable name="rottempUnits" select="'si_k'" />
        <xsl:variable name="mominertia" select="$thermoSection/cml:array[@dictRef='cc:moi.eigenvalues']"/>
        <xsl:variable name="mominertiaUnits" select="'atomic_units'"/>
        <xsl:variable name="molmass" select="$thermoSection/cml:scalar[@dictRef='cc:molmass']"/>
        <xsl:variable name="molmassUnits" select="'nonsi_amu'"/>
        
        <xsl:value-of select="concat('temperature:',$temperature,'#;#')"/>
        <xsl:value-of select="concat('temperatureUnits:',translate($temperatureUnits,':','_'),'#;#')"/>
        <xsl:value-of select="concat('pressure:',$pressure,'#;#')"/>
        <xsl:value-of select="concat('pressureUnits:',translate($pressureUnits,':','_'),'#;#')"/>
        <xsl:value-of select="concat('symmnumb: ',$symmnumb,'#;#',
            'rottemp: ',$rottemp,'#;#',
            'rottempUnits: ',$rottempUnits,'#;#',
            'mominertia: ',$mominertia,'#;#',
            'mominertiaUnits: ',$mominertiaUnits,'#;#',
            'molmass: ',$molmass,'#;#',
            'molmassUnits: ',$molmassUnits,'#;#')"/>
        </xsl:template>
    <!-- Energies section (module) -->
    <xsl:template name="energiesSection">
        <xsl:variable name="finalEnergy" select="
            if(exists(.//module[@cmlx:templateRef='l502.footer']/list[@cmlx:templateRef='scfdone']//scalar[@dictRef='g:rbhflyp'])) then
                (.//module[@cmlx:templateRef='l502.footer']/list[@cmlx:templateRef='scfdone']//scalar[@dictRef='g:rbhflyp'])[last()]
             else if(exists(.//module[@cmlx:templateRef='l508']/scalar[@dictRef='g:rbhflyp'])) then 
                (.//module[@cmlx:templateRef='l508']/scalar[@dictRef='g:rbhflyp'])[last()]
             else
                (.//scalar[@dictRef='g:rbhflyp'])[last()]"/>
        <xsl:variable name="l502Module" select="(.//module[@cmlx:templateRef='l502.pcm'])[last()]"/>
        <xsl:variable name="l120Module" select="(.//module[@cmlx:templateRef='l120'])[last()]"/>
        <xsl:variable name="l804Module" select="(.//module[@cmlx:templateRef='l804_l906'])[last()]"/>     
        <xsl:variable name="l122Module" select="(.//module[@cmlx:templateRef='l122'])[last()]"/>
        <xsl:variable name="zeropointProperty" select=".//property[@dictRef='cc:zeropoint']"/>   
        <xsl:variable name="thermoDecomp" select=".//module[@cmlx:templateRef='l716.thermoprops']"/>   
        <xsl:variable name="uid" select="concat(generate-id($finalEnergy),generate-id($l502Module),generate-id($l120Module),generate-id($zeropointProperty),generate-id($l122Module))"/>
        
            <xsl:if test="exists($finalEnergy) or exists($l502Module) or exists($l120Module) or exists($zeropointProperty) or exists($l122Module)">
                        <xsl:if test="exists($finalEnergy)">
                            <xsl:value-of select="concat('electronicEnergy:',$finalEnergy,'#;#')"/>
                            <xsl:value-of select="concat('electronicEnergyUnits:',helper:printUnitSymbol($finalEnergy/@units),'#;#')"/>                                                                    
                        </xsl:if>
                        <xsl:if test="exists($l502Module//scalar[@dictRef='cc:dispenergy'])">
                            <xsl:value-of select="concat('dispersionEnergy:',$l502Module//scalar[@dictRef='cc:dispenergy'],'#;#')"/>
                            <xsl:value-of select="concat('dispersionEnergyUnits:',helper:printUnitSymbol($l502Module//scalar[@dictRef='cc:dispenergy']/@units),'#;#')"/>
                        </xsl:if>  
                        <xsl:if test="exists($l120Module)">
                            <xsl:variable name="method" select="tokenize($l120Module/array[@dictRef='cc:method'],'[\s]')"/>
                            <xsl:variable name="system" select="tokenize($l120Module/array[@dictRef='cc:system'],'[\s]')"/>
                            <xsl:variable name="energy" select="tokenize($l120Module/array[@dictRef='cc:energy'],'[\s]')"/>        
                            <xsl-text>oniomEnergyDecomp: method system energy units &#xa;</xsl-text>
                            <xsl:for-each select="1 to count($method)">
                                <xsl:variable name="outerIndex" select="."/>
                                <xsl:value-of select="concat($method[$outerIndex], ' ', $system[$outerIndex], ' ', $energy[$outerIndex], ' ', 'Eh')"/>                                    
                            </xsl:for-each>
                            <xsl-text>#;#</xsl-text>
                            <xsl:value-of select="concat('oniomExtrapolatedEnergy:',$l120Module/scalar[@dictRef='cc:extraenergy'],'#;#')"/>
                            <xsl-text>oniomExtrapolatedEnergyUnits:Eh#;#</xsl-text>
                        </xsl:if>
                        <xsl:if test="exists($zeropointProperty)">
                            <xsl-text>zeroPointEnergyCorr:</xsl-text>
                                <xsl:value-of select="$zeropointProperty/list[@id='l716.zeropoint']/ scalar[@dictRef='cc:zpe.correction']"/>
                            <xsl-text>#;#</xsl-text>
                            <xsl-text>zeroPointEnergyCorrUnits:</xsl-text>
                             <xsl:value-of select="helper:printUnitSymbol($zeropointProperty/list[@id='l716.zeropoint']/ scalar[@dictRef='cc:zpe.correction']/@units)"></xsl:value-of>
                            <xsl-text>#;#</xsl-text>
                            <xsl-text>thermalEnergyCorr:</xsl-text>
                                <xsl:value-of select="$zeropointProperty/list[@id='l716.zeropoint']/scalar[@dictRef='cc:zpe.thermalcorrener']"/>
                            <xsl-text>#;#</xsl-text>
                            <xsl-text>thermalEnergyCorrUnits:</xsl-text>
                                <xsl:value-of select="helper:printUnitSymbol($zeropointProperty/list[@id='l716.zeropoint']/scalar[@dictRef='cc:zpe.thermalcorrener']/@units)"></xsl:value-of>
                            <xsl-text>#;#</xsl-text>
                            <xsl-text>enthalpyCorr:</xsl-text>
                                <xsl:value-of select="$zeropointProperty/list[@id='l716.zeropoint']/scalar[@dictRef='cc:zpe.thermalcorrenthalpy']"/>
                            <xsl-text>#;#</xsl-text>
                            <xsl-text>enthalpyCorrUnits:
                            </xsl-text>
                                <xsl:value-of select="helper:printUnitSymbol($zeropointProperty/list[@id='l716.zeropoint']/scalar[@dictRef='cc:zpe.thermalcorrenthalpy']/@units)"></xsl:value-of>
                            <xsl-text>#;#</xsl-text>
                            <xsl-text>gibbsFreeEnergyCorr:</xsl-text>
                                <xsl:value-of select="$zeropointProperty/list[@id='l716.zeropoint']/scalar[@dictRef='cc:zpe.thermalcorrgfe']"/>
                            <xsl-text>#;#</xsl-text>
                            <xsl-text>gibbsFreeEnergyCorrUnits:</xsl-text>
                                <xsl:value-of select="helper:printUnitSymbol($zeropointProperty/list[@id='l716.zeropoint']/scalar[@dictRef='cc:zpe.thermalcorrgfe']/@units)"></xsl:value-of>
                            <xsl-text>#;#</xsl-text>
                            <xsl-text>zeroPointEnergy:</xsl-text>
                                <xsl:value-of select="$zeropointProperty/list[@id='l716.zeropoint']/scalar[@dictRef='cc:zpe.sumelectzpe']"/>
                            <xsl-text>#;#</xsl-text>
                            <xsl-text>zeroPointEnergyUnits:</xsl-text>
                                <xsl:value-of select="helper:printUnitSymbol($zeropointProperty/list[@id='l716.zeropoint']/scalar[@dictRef='cc:zpe.sumelectzpe']/@units)"></xsl:value-of>
                            <xsl-text>#;#</xsl-text>
                            <xsl-text>thermalEnergy:</xsl-text>
                                <xsl:value-of select="$zeropointProperty/list[@id='l716.zeropoint']/scalar[@dictRef='cc:zpe.sumelectthermal']"/>
                            <xsl-text>#;#</xsl-text>
                            <xsl-text>thermalEnergyUnits:</xsl-text>
                                <xsl:value-of select="helper:printUnitSymbol($zeropointProperty/list[@id='l716.zeropoint']/scalar[@dictRef='cc:zpe.sumelectthermal']/@units)"></xsl:value-of>
                            <xsl-text>#;#</xsl-text>
                            <xsl-text>enthalpy:</xsl-text>
                                <xsl:value-of select="$zeropointProperty/list[@id='l716.zeropoint']/scalar[@dictRef='cc:zpe.sumelectthermalent']"/>
                            <xsl-text>#;#</xsl-text>
                            <xsl-text>enthalpyUnits:</xsl-text>
                                <xsl:value-of select="helper:printUnitSymbol($zeropointProperty/list[@id='l716.zeropoint']/scalar[@dictRef='cc:zpe.sumelectthermalent']/@units)"></xsl:value-of>
                            <xsl-text>#;#</xsl-text>
                            <xsl-text>gibbsFreeEnergy:</xsl-text>
                                <xsl:value-of select="$zeropointProperty/list[@id='l716.zeropoint']/scalar[@dictRef='cc:zpe.sumelectthermalfe']"/>
                            <xsl-text>#;#</xsl-text>    
                            <xsl-text>gibbsFreeEnergyUnits:</xsl-text>
                                <xsl:value-of select="helper:printUnitSymbol($zeropointProperty/list[@id='l716.zeropoint']/scalar[@dictRef='cc:zpe.sumelectthermalfe']/@units)"></xsl:value-of>
                            <xsl-text>#;#</xsl-text>
                        </xsl:if>
                        <xsl:if test="exists($thermoDecomp)">
                            <xsl-text>entropy:</xsl-text>
                                <xsl:value-of select="$thermoDecomp/list[@cmlx:templateRef='total']/scalar[@dictRef='cc:s.total']"/>
                            <xsl-text>#;#</xsl-text>    
                            <xsl-text>entropyTransl:</xsl-text>
                            <xsl:value-of select="$thermoDecomp/list[@cmlx:templateRef='trans']/scalar[@dictRef='cc:s.trans']"/>
                            <xsl-text>#;#</xsl-text>    
                            <xsl-text>entropyRot:</xsl-text>
                            <xsl:value-of select="$thermoDecomp/list[@cmlx:templateRef='rot']/scalar[@dictRef='cc:s.rot']"/>
                            <xsl-text>#;#</xsl-text> 
                            <xsl-text>entropyVib:</xsl-text>
                            <xsl:value-of select="$thermoDecomp/list[@cmlx:templateRef='vib']/scalar[@dictRef='cc:s.vob']"/>
                            <xsl-text>#;#</xsl-text> 
                            <xsl-text>thermalEnergyTransl:</xsl-text>
                            <xsl:value-of select="$thermoDecomp/list[@cmlx:templateRef='trans']/scalar[@dictRef='cc:ethermo.trans']"/>
                            <xsl-text>#;#</xsl-text>    
                            <xsl-text>thermalEnergyRot:</xsl-text>
                            <xsl:value-of select="$thermoDecomp/list[@cmlx:templateRef='rot']/scalar[@dictRef='cc:ethermo.rot']"/>
                            <xsl-text>#;#</xsl-text> 
                            <xsl-text>thermalEnergyVib:</xsl-text>
                            <xsl:value-of select="$thermoDecomp/list[@cmlx:templateRef='vib']/scalar[@dictRef='cc:ethermo.vib']"/>
                            <xsl-text>#;#</xsl-text> 
                            <xsl-text>entropyUnits:nonsi2:cal.mol-1K-1#;#</xsl-text>
                            <xsl-text>thermalContributionUnits:nonsi2:kcal.mol-1#;#</xsl-text>
                        </xsl:if>
                        <xsl:if test="exists($l122Module)">
                                <xsl:value-of select="concat('correctedCounterpoiseEnergy:',$l122Module/scalar[@dictRef='g:counterpoiseEnergy'],'#;#')"/>
                                <xsl:value-of select="concat('BSSEEnergy:',$l122Module/scalar[@dictRef='g:counterpoiseBSSE'],'#;#')"/>
                        </xsl:if>                                    
            </xsl:if>     
                            
            <!--<xsl:if test="exists($l804Module)">
                <xsl:variable name="spinComponentT2" select="tokenize($l804Module/list[@cmlx:templateRef='spincomponents']/array[@dictRef='cc:T2'],'[\s]')"/>
                <xsl:variable name="spinComponentE2" select="tokenize($l804Module/list[@cmlx:templateRef='spincomponents']/array[@dictRef='cc:E2'],'[\s]')"/>
                <xsl:variable name="spinType" select="tokenize('alpha-alpha alpha-beta beta-beta','[\s]')"/>
                <table class="display" id="energiesT-{generate-id($l804Module)}">
                    <thead>
                        <tr>
                            <th> </th>
                            <th> </th>
                            <th> </th>
                            <th> </th>
                            <th> </th>                                            
                        </tr>
                    </thead>
                    <tbody>
                        <xsl:for-each select="1 to count($spinComponentT2)">
                            <xsl:variable name="outerIndex" select="."/>
                            <tr>
                                <td><xsl:value-of select="$spinType[$outerIndex]"/></td>
                                <td>T2 = </td>
                                <td><xsl:value-of select='$spinComponentT2[$outerIndex]'/></td>
                                <td>E2 = </td>
                                <td><xsl:value-of select="$spinComponentE2[$outerIndex]"/></td>
                            </tr>                               
                        </xsl:for-each>
                        <tr>
                            <td></td>
                            <td>ANorm</td>
                            <td><xsl:value-of select="$l804Module//scalar[@dictRef='cc:anorm']"/></td>
                            <td></td>
                            <td></td>
                        </tr> 
                        <tr>
                            <td></td>
                            <td>E2</td>
                            <td><xsl:value-of select="$l804Module//scalar[@dictRef='cc:e2']"/></td>
                            <td></td>                                            
                            <td></td>
                        </tr> 
                        <tr>
                            <td></td>
                            <td>EUMP2</td>                                    
                            <td><xsl:value-of select="$l804Module//scalar[@dictRef='cc:eump2']"/></td>
                            <td></td>
                            <td></td>
                        </tr>
                    </tbody>
                </table>
                <script type="text/javascript">
                    $(document).ready(function(){
                        $("table#energiesT-<xsl:value-of select="generate-id($l804Module)"/>").dataTable({                                    
                            "bFilter": false,
                            "bPaginate": false,
                            "bSort": false,
                            "bInfo": false                                            
                        });                                    
                    });
                    
                </script>
            </xsl:if> 
                                                        
                            <xsl:variable name="archiveEnergies" select=".//module[@dictRef='cc:finalization']//module[@cmlx:templateRef='l9999.archive']//list[@dictRef='g:archive.namevalue']"/>                                                            
                            <xsl:if test="$archiveEnergies != ''">
                                <table class="display" id="energiesT-{generate-id($archiveEnergies)}">
                                    <thead>
                                        <tr>
                                            <th>Energy</th>
                                            <th>Value</th>
                                            <th>Units</th>                                   
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <xsl:for-each select="$archiveEnergies/scalar">
                                            <xsl:variable name="field" select="."/>
                                            <xsl:if test="matches($field,'.*=.*')">
                                                <xsl:variable name="splittedField" select="tokenize($field,'=')"/>
                                                <xsl:if test="gaussian:isMethod($splittedField[1])">
                                                    <tr>
                                                        <td><xsl:value-of select="$splittedField[1]"/></td>
                                                        <td class="right"><xsl:value-of select="$splittedField[2]"/></td>
                                                        <td><xsl:value-of select="helper:printUnitSymbol('nonsi:hartree')"/></td>
                                                    </tr>                                                   
                                                </xsl:if>
                                            </xsl:if>
                                        </xsl:for-each>    
                                    </tbody>
                                </table>    
                                <script type="text/javascript">
                                    $(document).ready(function(){
                                        $("table#energiesT-<xsl:value-of select="generate-id($archiveEnergies)"/>").dataTable({                                    
                                            "bFilter": false,
                                            "bPaginate": false,
                                            "bSort": false,
                                            "bInfo": false,
                                            "aoColumnDefs" : [
                                                { "sClass": "text-right", "aTargets": [ 1 ] },
                                                { "sClass": "nowrap", "aTargets": [ 0 ] }
                                            ],
                                        });                                    
                                    });                                    
                                </script>
                            </xsl:if>
                    </div> 
                </div>
            </div>
        </div>         -->
    </xsl:template>
    
    <!-- Energies section (module) -->
    <xsl:template name="energiesFragmentedSection">
        <xsl:variable name="finalEnergy" select="
            if(exists(.//module[@cmlx:templateRef='l502.footer']/list[@cmlx:templateRef='scfdone']//scalar[@dictRef='g:rbhflyp'])) then
                (.//module[@cmlx:templateRef='l502.footer']/list[@cmlx:templateRef='scfdone']//scalar[@dictRef='g:rbhflyp'])       
            else if(exists(.//module[@cmlx:templateRef='l508']/scalar[@dictRef='g:rbhflyp'])) then 
                (.//module[@cmlx:templateRef='l508']/scalar[@dictRef='g:rbhflyp'])[last()]
            else
                (.//scalar[@dictRef='g:rbhflyp'])[last()]"/>
        
        <xsl:variable name="l502Module" select="(.//module[@cmlx:templateRef='l502.pcm'])"/>
        <xsl:variable name="l120Module" select="(.//module[@cmlx:templateRef='l120'])"/>     
        <xsl:variable name="l122Module" select="(.//module[@cmlx:templateRef='l122'])"/>
        <xsl:variable name="zeropointProperty" select=".//property[@dictRef='cc:zeropoint']"/>                        
        <xsl:variable name="uid" select="concat(generate-id($finalEnergy[1]),generate-id($l502Module[1]),generate-id($l120Module[1]),generate-id($zeropointProperty[1]),generate-id($l122Module[1]))"/>
                
        <xsl:if test="exists($finalEnergy) or exists($l502Module) or exists($l120Module) or exists($zeropointProperty) or exists($l122Module)">
            <xsl:if test="exists($finalEnergy)">
                <xsl:value-of select="concat('electronicEnergy:',$finalEnergy,'#;#')"/>
                <xsl:value-of select="concat('electronicEnergyUnits:',helper:printUnitSymbol($finalEnergy/@units),'#;#')"/>                                                                    
            </xsl:if>
            <xsl:if test="exists($l502Module//scalar[@dictRef='cc:dispenergy'])">
                <xsl:value-of select="concat('dispersionEnergy:',$l502Module//scalar[@dictRef='cc:dispenergy'],'#;#')"/>
                <xsl:value-of select="concat('dispersionEnergyUnits:',helper:printUnitSymbol($l502Module//scalar[@dictRef='cc:dispenergy']/@units),'#;#')"/>
            </xsl:if>  
            <xsl:if test="exists($l120Module)">
                <xsl:variable name="method" select="tokenize($l120Module/array[@dictRef='cc:method'],'[\s]')"/>
                <xsl:variable name="system" select="tokenize($l120Module/array[@dictRef='cc:system'],'[\s]')"/>
                <xsl:variable name="energy" select="tokenize($l120Module/array[@dictRef='cc:energy'],'[\s]')"/>        
                <xsl-text>oniomEnergyDecomp: method system energy units &#xa;</xsl-text>
                <xsl:for-each select="1 to count($method)">
                    <xsl:variable name="outerIndex" select="."/>
                    <xsl:value-of select="concat($method[$outerIndex], ' ', $system[$outerIndex], ' ', $energy[$outerIndex], ' ', 'Eh')"/>                                    
                </xsl:for-each>
                <xsl-text>#;#</xsl-text>
                <xsl:value-of select="concat('oniomExtrapolatedEnergy:',$l120Module/scalar[@dictRef='cc:extraenergy'],'#;#')"/>
                <xsl-text>oniomExtrapolatedEnergyUnits:Eh#;#</xsl-text>
            </xsl:if>
                             
            <xsl:if test="exists($zeropointProperty)">                 
                <xsl-text>zeroPointEnergyCorr:</xsl-text>
                <xsl:value-of select="$zeropointProperty/list[@id='l716.zeropoint']/ scalar[@dictRef='cc:zpe.correction']"/>
                <xsl-text>#;#</xsl-text>
                <xsl-text>zeroPointEnergyCorrUnits:</xsl-text>
                <xsl:value-of select="helper:printUnitSymbol($zeropointProperty/list[@id='l716.zeropoint']/ scalar[@dictRef='cc:zpe.correction']/@units)"></xsl:value-of>
                <xsl-text>#;#</xsl-text>
                <xsl-text>thermalEnergyCorr:</xsl-text>
                <xsl:value-of select="$zeropointProperty/list[@id='l716.zeropoint']/scalar[@dictRef='cc:zpe.thermalcorrener']"/>
                <xsl-text>#;#</xsl-text>
                <xsl-text>thermalEnergyCorrUnits:</xsl-text>
                <xsl:value-of select="helper:printUnitSymbol($zeropointProperty/list[@id='l716.zeropoint']/scalar[@dictRef='cc:zpe.thermalcorrener']/@units)"></xsl:value-of>
                <xsl-text>#;#</xsl-text>
                <xsl-text>thermalEnthalpyCorr:</xsl-text>
                <xsl:value-of select="$zeropointProperty/list[@id='l716.zeropoint']/scalar[@dictRef='cc:zpe.thermalcorrenthalpy']"/>
                <xsl-text>#;#</xsl-text>
                <xsl-text>thermalEnthalpyCorrUnits:</xsl-text>
                <xsl:value-of select="helper:printUnitSymbol($zeropointProperty/list[@id='l716.zeropoint']/scalar[@dictRef='cc:zpe.thermalcorrenthalpy']/@units)"></xsl:value-of>
                <xsl-text>#;#</xsl-text>
                <xsl-text>thermalGibbsCorr:</xsl-text>
                <xsl:value-of select="$zeropointProperty/list[@id='l716.zeropoint']/scalar[@dictRef='cc:zpe.thermalcorrgfe']"/>
                <xsl-text>#;#</xsl-text>
                <xsl-text>thermalGibbsCorrUnits:</xsl-text>
                <xsl:value-of select="helper:printUnitSymbol($zeropointProperty/list[@id='l716.zeropoint']/scalar[@dictRef='cc:zpe.thermalcorrgfe']/@units)"></xsl:value-of>
                <xsl-text>#;#</xsl-text>
                <xsl-text>zeroPointEnergy:</xsl-text>
                <xsl:value-of select="$zeropointProperty/list[@id='l716.zeropoint']/scalar[@dictRef='cc:zpe.sumelectzpe']"/>
                <xsl-text>#;#</xsl-text>
                <xsl-text>zeroPointEnergyUnits:</xsl-text>
                <xsl:value-of select="helper:printUnitSymbol($zeropointProperty/list[@id='l716.zeropoint']/scalar[@dictRef='cc:zpe.sumelectzpe']/@units)"></xsl:value-of>
                <xsl-text>#;#</xsl-text>
                <xsl-text>thermalEnergy:</xsl-text>
                <xsl:value-of select="$zeropointProperty/list[@id='l716.zeropoint']/scalar[@dictRef='cc:zpe.sumelectthermal']"/>
                <xsl-text>#;#</xsl-text>
                <xsl-text>thermalEnergyUnits:</xsl-text>
                <xsl:value-of select="helper:printUnitSymbol($zeropointProperty/list[@id='l716.zeropoint']/scalar[@dictRef='cc:zpe.sumelectthermal']/@units)"></xsl:value-of>
                <xsl-text>#;#</xsl-text>
                <xsl-text>enthalpy:</xsl-text>
                <xsl:value-of select="$zeropointProperty/list[@id='l716.zeropoint']/scalar[@dictRef='cc:zpe.sumelectthermalent']"/>
                <xsl-text>#;#</xsl-text>
                <xsl-text>enthalpyUnits:</xsl-text>
                <xsl:value-of select="helper:printUnitSymbol($zeropointProperty/list[@id='l716.zeropoint']/scalar[@dictRef='cc:zpe.sumelectthermalent']/@units)"></xsl:value-of>
                <xsl-text>#;#</xsl-text>
                <xsl-text>gibbsFreeEnergy:</xsl-text>
                <xsl:value-of select="$zeropointProperty/list[@id='l716.zeropoint']/scalar[@dictRef='cc:zpe.sumelectthermalfe']"/>
                <xsl-text>#;#</xsl-text>    
                <xsl-text>gibbsFreeEnergyUnits:</xsl-text>
                <xsl:value-of select="helper:printUnitSymbol($zeropointProperty/list[@id='l716.zeropoint']/scalar[@dictRef='cc:zpe.sumelectthermalfe']/@units)"></xsl:value-of>
                <xsl-text>#;#</xsl-text>
            </xsl:if>
            <xsl:if test="exists($l122Module)">
                <xsl:value-of select="concat('correctedCounterpoiseEnergy:',$l122Module/scalar[@dictRef='g:counterpoiseEnergy'],'#;#')"/>
                <xsl:value-of select="concat('BSSEEnergy:',$l122Module/scalar[@dictRef='g:counterpoiseBSSE'],'#;#')"/>
            </xsl:if>                                               
        </xsl:if>
        
    </xsl:template>

    <!-- Spin section -->
    <xsl:template name ="spinSection">
        <xsl:variable name="mullikenSpin" select="(.//module[@cmlx:templateRef='l601.mullikenspin'])[last()]"/>
        <xsl:variable name="footer" select="(.//module[@cmlx:templateRef='l502.footer2'])[last()]"/>
        <xsl:if test="exists($mullikenSpin) or exists($footer)">
            <xsl:variable name="uid" select="concat(generate-id($mullikenSpin), generate-id($footer))"/> 

            <xsl:if test="exists($mullikenSpin)">
                <xsl:variable name="serial" select="tokenize($mullikenSpin/array[@dictRef='cc:serial'],'[\s]')"/>
                <xsl:variable name="elementtype" select="tokenize($mullikenSpin/array[@dictRef='cc:elementType'],'[\s]')"/>
                <xsl:variable name="charge" select="tokenize($mullikenSpin/array[@dictRef='x:charge'],'[\s]')"/>
                <xsl-text>mullikenSpinDensity:</xsl-text>
                <xsl:for-each select="1 to count($serial)">
                    <xsl:variable name="outerIndex" select="."/>
                    <xsl:value-of select="concat(format-number(number($charge[$outerIndex]),'#0.000000'),' ')"/>                                        
                </xsl:for-each>                                            
                <xsl-text>#;#</xsl-text>
            </xsl:if>
                         
            <xsl:if test="exists($footer)">
                
                <xsl:value-of select="concat('spinSquared:',$footer/scalar[@dictRef='cc:spincontamination'],'#;#')"/>
            </xsl:if>
        </xsl:if>    
    </xsl:template>
   
    <!-- Frequencies section -->
    <xsl:template name="frequencies">
        <xsl:variable name="vibrations" select="if(exists(.//module[@cmlx:templateRef='l716.freq.high.precision.chunkx' and @dictRef='cc:vibrations'])) then
                                                    .//module[@cmlx:templateRef='l716.freq.high.precision.chunkx' and @dictRef='cc:vibrations']
                                                else 
                                                    .//module[@cmlx:templateRef='l716.freq.chunkx' and @dictRef='cc:vibrations']
                                                 "/>
        <xsl:if test="exists($vibrations)">
            <xsl:variable name="vindex" select="count(preceding-sibling::*/descendant::module[@cmlx:templateRef='l716.freq.chunkx']/ancestor-or-self::module[@dictRef='cc:finalization']/molecule) + 1" />
            <xsl:variable name="uid" select="generate-id($vibrations)"/> 
            <xsl:variable name="frequency" select="tokenize($vibrations/array[@dictRef='cc:frequency'],'[\s]')"/>
            <xsl-text>frequencies:</xsl-text>
            <xsl:for-each select="1 to count($frequency)">
                <xsl:variable name="outerIndex" select="."/>
                <xsl:value-of select="concat($frequency[$outerIndex],' ')"/>
            </xsl:for-each>  
            <xsl-text>#;#</xsl-text>
            <xsl:text>freqUnits:nonsi_cm-1#;#</xsl:text>
            <xsl:variable name="vibrDispl" select="$vibrations/cml:array[@dictRef='cc:displacement']"/>
            <xsl:value-of select="concat('vibrdispl: ',$vibrDispl,'#;#')"/>
            <xsl:text>vibrdisplUnits: nonsi_angstrom #;# </xsl:text>
        </xsl:if>  
    </xsl:template>

    <!-- ESP charges -->
    <xsl:template name="espcharges">
        <xsl:variable name="espcharges" select="(.//module[@cmlx:templateRef='l602.electrostatic']/module[@cmlx:templateRef='espcharges'])[last()]"/>
        <xsl:if test="exists($espcharges)">
            <xsl:variable name="serial" select="tokenize($espcharges/array[@dictRef='cc:serial'], '\s+')"/>
            <xsl:variable name="atomType" select="tokenize($espcharges/array[@dictRef='cc:elementType'], '\s+')"/>
            <xsl:variable name="charges" select="tokenize($espcharges/array[@dictRef='g:espcharge'],'\s+')"/>
            <xsl-text>espCharges:</xsl-text>                                                                           
            <xsl:for-each select="1 to count($serial)">
                <xsl:variable name="outerIndex" select="."/>
                <xsl:value-of select="concat($charges[$outerIndex],' ')"/>                                                    
            </xsl:for-each>      
            <xsl-text>#;#</xsl-text>  
        </xsl:if>
    </xsl:template>

    <!-- Mulliken charges  -->
    <xsl:template name="mullikenCharges">
        <xsl:variable name="mulliken" select="(.//module[@dictRef='cc:finalization']//module[@cmlx:templateRef='l601.mullik'][matches(descendant::scalar[@dictRef='g:title']/text(), 'Mulliken\s*(atomic)?\s*charges:')]/list[@cmlx:templateRef='row'])[last()]"/>        
        <xsl:if test="exists($mulliken)">
            <xsl:variable name="serial" select="tokenize($mulliken/array[@dictRef='cc:serial'], '\s+')"/>
            <xsl:variable name="atomType" select="tokenize($mulliken/array[@dictRef='cc:elementType'], '\s+')"/>
            <xsl:variable name="charges" select="tokenize($mulliken/array[@dictRef='x:charge'],'\s+')"/>
            <xsl-text>mullikenCharges:</xsl-text>                                                                                              
            <xsl:for-each select="1 to count($serial)">
                <xsl:variable name="outerIndex" select="."/>
                <xsl:value-of select="concat($charges[$outerIndex],' ')"/>                                                   
            </xsl:for-each>  
            <xsl-text>#;#</xsl-text>                         
        </xsl:if>
    </xsl:template>
   
    <!-- Dipole moment -->
    <xsl:template name="dipoleMoment">
        <xsl:variable name="multipole" select="(.//list[@cmlx:templateRef='multipole'])[last()]"/>
        <xsl:if test="exists($multipole)">            
            <xsl:variable name="dipole"     select="tokenize($multipole/array[@dictRef='cc:dipole'],'\s+')"/>
            <xsl:variable name="quadrupole" select="tokenize(concat(($multipole/array[@dictRef='cc:quadrupole' and @size='3'])[1],' ',($multipole/array[@dictRef='cc:quadrupole' and @size='3'])[2]),'\s+')"/>
            <xsl:variable name="dipoleid" select="generate-id($multipole/array[@dictRef='cc:dipole'])"/>
            <xsl:variable name="quadrupoleid" select="generate-id(($multipole/array[@dictRef='cc:quadrupole'])[1])"/>
            <xsl:variable name="uid" select="concat($dipoleid,$quadrupoleid)"/>

            <xsl:value-of select="concat('dipoleMomentVector:',$dipole[1],' ',$dipole[2],' ',$dipole[3],'#;#')"/>
            <xsl:value-of select="concat('dipoleMomentTotal:',$multipole//scalar[@dictRef='x:dipole'],'#;#')"/>
            <xsl-text>quadrupoleMoment:XX XY ZZ XY XZ YZ &#xa;</xsl-text>
            <xsl:value-of select="$quadrupole"/> 
            <xsl-text>#;#</xsl-text>
        </xsl:if>
    </xsl:template>            
            

   
    
    <!-- Override default templates -->
    <xsl:template match="text()"/>
    <xsl:template match="*"/>    
            
</xsl:stylesheet>
