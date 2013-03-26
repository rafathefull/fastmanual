/*
  Nueva clase para manejar FastReport sin intervención del programador.
  (c)2013 Rafa Carmona
*/
#include "hbclass.ch"
#include "hbxml.ch"
#include "FastRepH.ch"

#define CRLF         hb_osnewline()
#define NTRIM(n)    ( LTrim( Str( n ) ) )

#define df_dbf    1
#define df_alias  2
#define df_index  3
#define df_filtro 4
#define df_force_index 5
#define df_expr_index 6

#define df_func_name        1
#define df_func_description 2
#define df_func_category    3

MEMVAR IMPRIMELOGO, CODUSU  // Uso privado.  Si lo quereis quitar, quitarlo

CLASS TFASTMANUAL
      HIDDEN:
        DATA oDoc    
  
      EXPORT:  
        DATA cReport  INIT ""     //Contiene el nombre del reporte
        DATA cXml     INIT ""     // Ruta + Nombre del XML a cargar
        DATA cDbf_Master          // Dbf Principal sobre la que va a correr MasterDetail del FastReport

        DATA aDbfs                // { { DBF, ALIAS, INDEX, FILTER , DBF_FORCE_INDEX , EXPRESION_INDEX }}  , Se abren si no están , si no , se reutilizan
        DATA aDbfs_Open           // Tablas que deberemos cerrar nosotros, solo las que hemos abierto.
        DATA aFunctions           // { { FUNC_NAME, FUNC_DESCRIPTION, FUNC_CATEGORY }}
        DATA range1, range2, range3 // Rangos de impresion para fastreport
        DATA aMaster_Detail         // Relación de mater/detail

        DATA bStart               // Evalua ANTES de crear el reporte.
        DATA bWhile               // TODO: Pendiente
        DATA bFor                 // Evalua en cada fila de la MasterData

        DATA lErrorMount INIT .F. // Hubo algun tipo de error

        DATA lOem        INIT .T.
        DATA lOk         INIT .F.

        DATA oFrPrn               // Objeto FastReport

 
        METHOD New()
        METHOD Run()                        // lanza el Report 
        METHOD OpenDbfs()                   // Apertura de tablas 
        METHOD CloseDbfs()                  // Cierra las tablas que hemos abierto
        METHOD LoadXML( cFile )             // Cargar el XML y alimenta el objeto
        METHOD End()
        METHOD SetPrinter( cPrinter ) INLINE ::cPrinter := cPrinter
        METHOD SetDesign( lDisenyo )  INLINE ::lDisenyo := lDisenyo
        METHOD SetDirect( lDirecto )  INLINE ::lDirecto := lDirecto        
        METHOD SetTitle( cTitulo )    INLINE ::cTitulo  := cTitulo
        METHOD OutputFile( cNomFic )  

      PROTECTED:
        DATA lDisenyo  INIT .F.   // Muestra el diseñador de fastreport
        DATA lDirecto  INIT .F.   // Imprimir directo
        DATA cPrinter  INIT ""    // Indica la impresora por la que imprimir
        DATA cTitulo   INIT "ManualFast"
        DATA cNomFic   INIT ""    // Si queremos que imprima directamente a un fichero PDF

      HIDDEN:
        METHOD SetRange()                   // Establece el rango para el reporte
        METHOD SetWorkAreas( oNode )
        METHOD SetMasterDetail( oNode )
        METHOD SetFunctions( oNode )
        METHOD AddDbf( cDbf, cAlias, cIndex, cFilter ,lForce_Index , cExprInd )
        METHOD AddMasterDetail( cMaster, cDetail, cExpression, lSyncro )
        METHOD AddFunction( cName, cDescription, cCategory )
        METHOD WorkAreas()
        METHOD Master_detail()
        METHOD Functions()
        METHOD RunReport( )
        METHOD FilePrint( cExport  )

END CLASS

METHOD New( cReport , bStart, bWhile, bFor, cXml ) CLASS TFASTMANUAL
    Local cVar_bWhile := cReport + "_bwhile"
    Local cVar_bFor   := cReport + "_bfor"

    ::cReport := cReport
    ::cXml    := cXml

    ::bStart := bStart
    ::bWhile := bWhile
    ::bFor   := bFor

    ::aDbfs      := {}
    ::aDbfs_Open := {}
    ::aFunctions := {}
    ::aMaster_Detail := {}

    ::lOk := ::LoadXML() 

    if ::lOk

       PUBLIC &cVar_bWhile := bWhile // Creo una variable publica que será evalua en FastReport
       PUBLIC &cVar_bFor   := bFor   // Creo una variable publica que será evalua en FastReport
    endif


RETURN Self  

****************************************************************************************
****************************************************************************************
METHOD Run() CLASS TFASTMANUAL
  
  if ::lOk
    if ::OpenDbfs()

       dbselectarea( ::cDbf_Master )
       
       if !empty( ::bStart )
          ( ::cDbf_Master )->( DbSeek( Eval( ::bStart ) , .T. ) )
       else   
          ( ::cDbf_Master )->( DbGoTop() )
       endif
       
       ::oFrPrn := frReportManager():new()
       ::oFrPrn:SetEventHandler( "Report", "OnUserFunction", { | FName, aFParams | HB_ExecFromArray( FNAME, if(empty(aFParams), {} , aFParams )  ) } )
       ::oFrPrn:SetWorkArea( ::cDbf_Master, Select( ::cDbf_Master ), ::lOem, { ::range1, ::range2, ::range3} )

       ::WorkAreas()         // Indicamos a FastReports las Dbfs a usar.
       ::Master_detail() 
       ::Functions()
       
       ::RunReport( )

       ::oFrPrn:ClearDataSets()
       ::oFrPrn:DestroyFR()

    endif
    ::End()
  endif

RETURN NIL

****************************************************************************************
****************************************************************************************
METHOD End() CLASS TFASTMANUAL
    Local cVar_bWhile := ::cReport + "_bwhile"
    Local cVar_bFor   := ::cReport + "_bfor"

    ::CloseDbfs()
    
    __MXRelease( cVar_bWhile  )
    __MXRelease( cVar_bFor  )

RETURN NIL

****************************************************************************************
// Nos permite abrir unas dbfs a partir de un array
****************************************************************************************
METHOD OpenDbfs() CLASS TFASTMANUAL
    Local uSelect := Select()
    Local oError, x, cError, cFiltro

    for x := 1 TO len( ::aDbfs )
        BEGIN SEQUENCE
           if ( Select( ::aDbfs[ x, df_alias ] ) == 0 )     // Si la tabla no esta en uso
              USE ( ::aDbfs[ X, df_dbf ] ) ALIAS ( ::aDbfs[ x, df_alias ] ) NEW SHARED
              aadd( ::aDbfs_Open, ::aDbfs[ x, df_alias ] )  // Añadimos dbfs que tenemos que cerrar
           else
              DbSelectArea( ::aDbfs[ x, df_alias ] )
           endif
           if !empty( ::aDbfs[ x,df_index ] )
              if ::aDbfs[ x, df_force_index ]  // Forzamos REINDEX
                 INDEX ON &(::aDbfs[ x, df_expr_index ]) TO ( ::aDbfs[ x, df_index ] )
              else
                 DbSetIndex( ::aDbfs[ x, df_index ] )
              endif
           endif
           
           if !empty( ::aDbfs[ x, df_filtro ] )
               dbselectarea( ::aDbfs[ x, df_alias ] )
               cFiltro :=  ::aDbfs[ x, df_filtro ]
               Set Filter to &( cFiltro )
           endif

           if NETERR()
              ::lErrorMount := .T.
              Alert( "ERROR DE APERTURA EN " +  ::aDbfs[ X, df_dbf ] )
           endif
        RECOVER USING oError
           cError :=  "Descripcion: "+ oError:description  +CRLF+;
                      "Fichero    : "+ oError:Filename     +CRLF+;
                      "Codigo Gen.: "+ alltrim(Str(oError:GenCode ))+CRLF+;
                      "SubSistema : "+ UPPER( oError:SubSystem )    +CRLF+;
                      "Codigo Sub.: "+ alltrim(STR(oError:SubCode)) +CRLF+;
                      "Operacion  : "+ oError:Operation +;
                       if( !empty( oError:OsCode ) ,( CRLF + "DOS Error: " + NTRIM( oError:osCode) + CRLF ), CRLF )

            if upper( oError:SubSystem ) = "DBFNTX" .and. "NTX" $ upper( oError:Filename ) // oError:GenCode != 3  // Error de Apertura
              ::lErrorMount := .F.
            else
              ::lErrorMount := .T.
            endif
            alert(cError)
        END
    next

    if ::lErrorMount               // Hubo algun tipo de error
        if !empty( cError )
           alert( cError )
        endif
       ::CloseDbfs()
       Return NIL
    ENDIF

    Select( uSelect )

RETURN !( ::lErrorMount )

****************************************************************************************
// Cerramos todas las dbbfs abiertas por la clase
****************************************************************************************
METHOD CloseDbfs() CLASS TFASTMANUAL
    Local oError, cError , X
    
    FOR X := 1 TO Len( ::aDbfs_Open )
        BEGIN SEQUENCE
           ( ::aDbfs_Open[ X ] )->( DbCloseArea() )
        RECOVER USING oError
           cError :=  "Descripcion: "+ oError:description  +CRLF+;
                      "Fichero    : "+ oError:Filename     +CRLF+;
                      "Codigo Gen.: "+ alltrim(Str(oError:GenCode ))+CRLF+;
                      "SubSistema : "+ UPPER( oError:SubSystem )    +CRLF+;
                      "Codigo Sub.: "+ alltrim(STR(oError:SubCode)) +CRLF+;
                      "Operacion  : "+ oError:Operation +;
                      if( !empty( oError:OsCode ) ,( CRLF + "DOS Error: " + NTRIM( oError:osCode) + CRLF ), CRLF )
         END
    NEXT


RETURN Nil


****************************************************************************************
****************************************************************************************
METHOD LoadXML( ) CLASS TFASTMANUAL
   Local lOk := .T.
   Local cResponse
   Local oNode, oNext
   LOCAL lTengoRuta, nCount, cPath, cDirectory, cRutaReport := "\"

   if empty( ::cXML )                    // Si no envio el XML, busco uno igual que el Report pero con nombre .XML
        if file( ::cReport + ".xml")     // File() busca en la ruta de Clipper para poder configurar la ruta PATH
             lTengoruta := .f.
             nCount := 0
             cPath := Set(_SET_PATH)
             DO WHILE .T.
                cDirectory := Token( cPath, ";", ++nCount )
                IF Empty( cDirectory )
                   EXIT
                ENDIF
                // No uso file() porque busca en toda la ruta de Clipper
                if len(Directory(cDirectory + "\" + ::cReport + ".xml")) != 0
                   if lTengoruta
                      Alert("ATENCION !!! ; El report puede estar duplicado en: ;" + cRutaReport + ";" + cDirectory)
                   else
                      // Mantengo la primera que encuentra
                      cRutaReport := cDirectory
                      lTengoruta := .t.
                   endif
                endif
             ENDDO
           if lTengoruta
              ::cXml := ( cRutaReport + "\" + ::cReport + ".xml" )
           else
              alert("No puedo localizar el report")
              lOk := .f.
           endif
        else
           Alert("No se encuentra XML para definicion de listado.")
           lOk := .f.
        endif

        if !( lOk )
           return lOk
        endif
   endif     

   // Creamos un doc a partir de la respuesta obtenida de la peticion
   ::oDoc := TXmlDocument():New( memoread( ::cXml) )

   if ::oDoc:nStatus != HBXML_STATUS_OK
      lOk := .F.
      cResponse := "Error While Processing File: " + AllTrim( Str( ::oDoc:nLine ) ) + " # "+;
                    "Error: " + HB_XmlErrorDesc( ::oDoc:nError ) + " # "

      alert( cResponse )
      return lOk
   endif

  oNode := ::oDoc:FindFirst( "REPORT" )
  
  if oNode != NIL
     ::lOEm    := if( cValtoChar( oNode:GetAttribute( "oem" ) ) = "true", .T., .F. )
     ::SetRange( oNode )
     oNext := oNode:oChild 
     while oNext != NIL
           do case  
              case oNext:cName = "WORKAREAS"
                   ::SetWorkAreas( oNext:oChild )
              case oNext:cName = "MASTERDETAIL"
                   ::SetMasterDetail( oNext:oChild )
              case oNext:cName = "FUNCTIONS"
                   ::SetFunctions( oNext:oChild )
           end case 
           oNext := oNext:oNext
     end while
     
  else // No se encuentra, puede ser que se deba a un error
     lOk := .F.
     alert( "XML no es correcto.")
  endif

RETURN lOk


****************************************************************************************
****************************************************************************************
METHOD SetRange( oNode ) CLASS TFASTMANUAL
     Local range1, range2, range3

     if oNode != NIL
	     range1 := cValtoChar( oNode:GetAttribute( "range1" ) )
	     range2 := cValtoChar( oNode:GetAttribute( "range2" ) )
	     range3 := cValtoChar( oNode:GetAttribute( "range3" ) )
	 
	     do case
	        case range1 = "FIRST"
	             ::range1 := FR_RB_FIRST
	        case range1 = "CURRENT"
	             ::range1 := FR_RB_CURRENT
	        case range1 = "LAST"
	             ::range1 := FR_RE_LAST
	        otherwise
	             ::range1 = FR_RB_FIRST
	     end case

	     do case
	        case range2 = "FIRST"
	             ::range2 := FR_RB_FIRST
	        case range2 = "CURRENT"
	             ::range2 := FR_RB_CURRENT
	        case range2 = "LAST"
	             ::range2 := FR_RE_LAST
	        otherwise
	             ::range2 = FR_RE_LAST
	     end case

	     do case
	        case range3 = "FIRST"
	             ::range3 := FR_RB_FIRST
	        case range3 = "CURRENT"
	             ::range3:= FR_RB_CURRENT
	        case range3 = "LAST"
	             ::range3:= FR_RE_LAST
	        otherwise
	             ::range3 = 0
	     end case

	 endif    

RETURN NIL

*******************************************************************************
*******************************************************************************
METHOD SetWorkAreas( oNode ) CLASS TFASTMANUAL
    Local oNext := oNode
    Local lMaster, cDbf, cAlias, cIndex, cFilter, cExprInd, lForce_Index


    while oNext != NIL
          
          lMaster      := if( cValtoChar( oNext:GetAttribute("master") ) = "true", .T., .F. )
          cDbf         := oNext:GetAttribute("name") 
          cAlias       := oNext:GetAttribute("alias") 
          cIndex       := oNext:GetAttribute("index") 
          cFilter      := oNext:GetAttribute("filter") 
          cExprInd     := oNext:GetAttribute("expression_index") 
          lForce_Index := if( cValtoChar( oNext:GetAttribute("force_index") ) = "true", .T., .F. )

          if lMaster 
             ::cDbf_Master := cAlias
          endif
          
          ::AddDbf( cDbf, cAlias, cIndex, cFilter ,lForce_Index , cExprInd )
          
          oNext := oNext:oNext

    end while

RETURN NIL

*******************************************************************************
*******************************************************************************
METHOD SetMasterDetail( oNode ) CLASS TFASTMANUAL
   Local cMaster, cDetail, cExpression, lSyncro
   Local oNext := oNode

    while oNext != NIL
          
          cMaster     := oNext:GetAttribute("master") 
          cDetail     := oNext:GetAttribute("detail") 
          cExpression := oNext:GetAttribute("expression") 
          lSyncro     := if( cValtoChar( oNext:GetAttribute("syncro") ) = "true", .T., .F. )
          
          ::AddMasterDetail( cMaster, cDetail, cExpression, lSyncro )
          
          oNext := oNext:oNext

    end while

RETURN NIL

*******************************************************************************
*******************************************************************************
METHOD SetFunctions( oNode ) CLASS TFASTMANUAL
   Local cName, cDescription, cCategory
   Local oNext := oNode

    while oNext != NIL
          
          cName        := oNext:GetAttribute("name") 
          cDescription := oNext:GetAttribute("description") 
          cCategory    := oNext:GetAttribute("category") 
          
          ::AddFunction( cName, cDescription, cCategory )
          
          oNext := oNext:oNext

    end while

RETURN NIL


*******************************************************************************
*******************************************************************************
METHOD WorkAreas() CLASS TFASTMANUAL       
  Local aDbf, cDbf
       
  FOR EACH aDbf IN ::aDbfs
       if aDbf[ df_alias ] != ::cDbf_Master  // La master no se carga 
          cDbf := aDbf[ df_alias ]
          ::oFrPrn:SetWorkArea( cDbf , Select( cDbf ), .T. )
       endif   
  NEXT

RETURN NIL


*******************************************************************************
*******************************************************************************
METHOD Master_detail() CLASS TFASTMANUAL       
  Local aMaster, cMaster, cDetail, cExpression, lSyncro
       
  FOR EACH aMaster IN ::aMaster_Detail
      cMaster     := aMaster[1]
      cDetail     := aMaster[2]
      cExpression := aMaster[3]
      lSyncro     := aMaster[4]

      ::oFrPrn:SetMasterDetail( cMaster, cDetail,   &( "{ || "+  cExpression + " }") )

   NEXT

RETURN NIL

*******************************************************************************
*******************************************************************************
METHOD Functions() CLASS TFASTMANUAL       
  Local aFunction
       
  FOR EACH aFunction IN ::aFunctions
      ::oFrPrn:AddFunction( aFunction[ df_func_name ], aFunction[ df_func_category], aFunction[ df_func_description ] )
  NEXT

  // Declaramos funciones interesantes de Harbour 
//  ::oFrPrn:AddFunction( "Function Empty( aParam: Variant): Boolean", "[x]Harbour", "Devuelve .T. si la cadena esta vacia" )
  ::oFrPrn:AddFunction( "Function Left( aParam: String, nCount : Integer ): String", "[x]Harbour", "Extracts characters from the left side of a string" )
  ::oFrPrn:AddFunction( "Function Round( nNumber: Double, nDecimals : Integer ): Double", "[x]Harbour", "Rounds a numeric value to a specified number of digits " )
  ::oFrPrn:AddFunction( "Function CStr( uValue : Variant ): String", "[x]Harbour", "Converts a value to a character string." )
  ::oFrPrn:AddFunction( "Function SubStr( cValue : String, nStart : Integer, nCount : Integer ): String", "[x]Harbour", "Extracts a substring from a character string." )
  ::oFrPrn:AddFunction( "Function At( cSearch : String, cString : String, , nStart : Integer, nEnd : Integer ): Integer", "Locates the position of a substring within a character string" )
  ::oFrPrn:AddFunction( "Function OemToAnsi( cCadena : String ) : String" , "[x]Harbour", "Convierte una cadena de Oem a Ansi"  )
  ::oFrPrn:AddFunction( "Function AnsiToOem( cCadena : String  ) : String" , "[x]Harbour", "Convierte una cadena de Ansi a Oem"  )
  ::oFrPrn:AddFunction( "Function HB_UTF8TOSTR( cString : String, cCPID : String = EmptyVar) : String" , "[x]Harbour", "Convierte UTF8 a CP" )
  ::oFrPrn:AddFunction( "Function HB_STRTOUTF8( cString : String, cCPID : String = EmptyVar) : String" , "[x]Harbour", "Convierte CP a UTF8" )
  ::oFrPrn:AddFunction( "Function Val( cNumber : String ) : Integer","[x]Harbour", "Convierte un string en un numérico" )

  ::oFrPrn:AddFunction( "Function Evalua_bWhile( cReport: String ): Boolean", "Tesipro", "Evalua bWhile del LISTAME" )
  ::oFrPrn:AddFunction( "Function Evalua_bFor( cReport: String ): Boolean",   "Tesipro", "Evalua bFor del LISTAME" )

RETURN NIL

*******************************************************************************
*******************************************************************************
METHOD AddDbf( cDbf, cAlias, cIndex, cFilter ,lForce_Index , cExprInd )
     aadd(::aDbfs, { cDbf, cAlias, cIndex, cFilter ,lForce_Index , cExprInd } )
RETURN NIL

*******************************************************************************
*******************************************************************************
 METHOD AddMasterDetail( cMaster, cDetail, cExpression, lSyncro ) CLASS TFASTMANUAL
    aadd( ::aMaster_Detail, { cMaster, cDetail, cExpression, lSyncro } )
RETURN NIL

 METHOD AddFunction( cName, cDescription, cCategory ) CLASS TFASTMANUAL
    aadd( ::aFunctions, { cName, cDescription, cCategory } )
RETURN NIL
          

/*
 Funcion genérica que se usará para todos los reportes.
 Se encarga de buscar los reportes en la ruta determinada por SET PATH
 También se encarga de imprimir directamente en la impresora o pantalla o ponerse en modo diseño.
 */
METHOD RunReport(  )

    LOCAL lOk, lTengoRuta, nCount, cPath, cDirectory, cRutaReport := "\", cExport
    LOCAL aExpList := {"PDFExport", "HTMLExport", "RTFExport", "CSVExport",;
                        "XLSExport", "DotMatrixExport", "BMPExport", "JPEGExport",;
                        "TXTExport", "TIFFExport", "GIFExport",;
                        "SimpleTextExport", "MailExport", "XMLExport"}

    lOk := .t.
    // Pruebo poniendo la ruta de busqueda en perso.cfg
    if file( ::cReport + ".fr3")     // File() busca en la ruta de Clipper para poder configurar la ruta en el PERSO.CFG
         lTengoruta := .f.
         nCount := 0
         cPath := Set(_SET_PATH)
         DO WHILE .T.
            cDirectory := Token( cPath, ";", ++nCount )
            IF Empty( cDirectory )
               EXIT
            ENDIF
            // No uso file() porque busca en toda la ruta de Clipper
            if len(Directory(cDirectory + "\" + ::cReport + ".fr3")) != 0
               if lTengoruta
                  Alert("ATENCION !!! ; El report puede estar duplicado en: ;" + cRutaReport + ";" + cDirectory)
               else
                  // Mantengo la primera que encuentra
                  cRutaReport := cDirectory
                  lTengoruta := .t.
               endif
            endif
         ENDDO
       if lTengoruta
          ::oFrPrn:LoadFromFile( cRutaReport + "\" + ::cReport+ ".fr3" )
       else
          alert("No puedo localizar el report")
          lOk := .f.
       endif
    else
      if !( ::lDisenyo )
         Alert("No se encuentra definicion de listado.")
         lOk := .f.
      else
         Alert("No se encuentra definicion de listado. Se entra en modo Edicion para su creacion.")
      endif
    endif

    if lOk 
       //funciones( FrPrn )  // Insertamos las funciones que queramos usar en el reporte.
       variables( ::oFrPrn )  // Insertamos las funciones que queramos usar en el reporte.

       // Podemos determinar el fondo dinamicamente de esta manera.
       // En modo diseño el fondo puede ser bastante molesto estoy pensando solo ponerlo en modo preview
       ::oFrPrn:PrepareScript()
    

       ::oFrPrn:ReportOptions:SetName( ::cTitulo )
       ::oFrPrn:SetTitle( ::cTitulo )
       
    

      if ".TXT" $ UPPER( ::cNomFic ) .or. ".PDF" $ UPPER( ::cNomFic ) .or. ".HTM" $ ( ::cNomFic )
          if !empty ( ::cNomFic )
             do case
                case ".TXT" $ UPPER( ::cNomFic  )
                      cExport := aExpList[9]
                case ".PDF" $ UPPER( ::cNomFic  )
                      cExport := aExpList[1]
                case ".HTM" $ UPPER( ::cNomFic )
                     cExport := aExpList[2]
                otherwise
                     cExport := aExpList[9]
             end case
             ::oFrPrn:PrepareReport()
             ::FilePrint( cExport )   // Envia el fichero externo
          endif
      endif

       // Las 3 primeras, es porque se detecta que no  guarda la imagen en el PDF
       
       ::oFrPrn:SetProperty( "PDFExport", "Compressed", .T. )
       ::oFrPrn:SetProperty( "PDFExport", "EmbeddedFonts", .T. )
       ::oFrPrn:SetProperty( "PDFExport" ,"PrintOptimized",.T.)
       ::oFrPrn:SetProperty( "PDFExport", "OpenAfterExport", .T. )
       ::oFrPrn:SetProperty( "PDFExport", "Outline", .T. )
       ::oFrPrn:SetProperty( "PDFExport", "Author", CODUSU )
       ::oFrPrn:SetProperty( "PDFExport", "Subject", "" )
       ::oFrPrn:SetProperty( "PDFExport", "Creator", "TESIPRO SOLUTIONS,S.L" )

 
       if ::lDisenyo
          IMPRIMELOGO := .T.
          ::oFrPrn:DesignReport()
          IMPRIMELOGO := .F.
       else
          if !empty( ::cNomFic )
             ::oFrPrn:PrepareReport()
             ::oFrPrn:ReportOptions:SetName( ::cNomFic )
             ::oFrPrn:SetTitle( ::cNomFic )
             if ".PDF" $ UPPER( ::cNomFic  )
                 ::oFrPrn:SetProperty("PDFExport", "Title", ::cNomFic )
                 ::oFrPrn:SetProperty( "PDFExport" ,"EmbedFontsIfProtected",.t.)
                 //::oFrPrn:DoExport( "PDFExport" )
             endif    
             ::FilePrint( cExport )   // Envia el fichero externo
         else
           if !empty( ::cPrinter ) .or. ::lDirecto   // cPrinter ="" es por pantalla
              ::oFrPrn:PrepareReport()
              ::oFrPrn:PrintOptions:SetPrinter( ::cPrinter )   // Pasamos nombre de la impresora
              ::oFrPrn:PrintOptions:SetShowDialog( .f. )     // Si queremos mostrar el dialogo
              ::oFrPrn:Print( .t. )
           else
              IMPRIMELOGO := .T.
              ::oFrPrn:PrepareReport()
              ::oFrPrn:PreviewOptions:SetAllowEdit( .F. )
              // No incluyo los botones LOAD y SAVE
              // El 2048 activa botones especiales EXPORTAR A PDF y SENDMAIL ... no estan en la documentacion !!!
              ::oFrPrn:PreviewOptions:SetButtons(FR_PB_PRINT + FR_PB_EXPORT + FR_PB_ZOOM + FR_PB_FIND + FR_PB_OUTLINE + FR_PB_PAGESETUP + FR_PB_TOOLS + FR_PB_EDIT +FR_PB_NAVIGATOR + 2048)
              ::oFrPrn:PreviewOptions:SetZoomMode(FR_ZM_WHOLEPAGE)
              ::oFrPrn:ShowReport()
              IMPRIMELOGO := .F.
           endif
         endif 
       endif
    endif    

return lOk

METHOD FilePrint( cExport  ) CLASS TFASTMANUAL

   ::oFrPrn:SetProperty( cExport ,"FileName", ::cNomFic )
   ::oFrPrn:SetProperty( cExport ,"ShowDialog",.f.)
   ::oFrPrn:SetProperty( cExport ,"ShowProgress",.f.)
   ::oFrPrn:DoExport( cExport )

RETURN NIL


/* Indica el nombre de arhivo de salida.
   Creará un fichero según la extensión. 
   Soporte: TXT, PDF, HTML */
METHOD OutputFile( cNomFic ) CLASS TFASTMANUAL
    if !empty( cNomFic )
       ::cNomFic  := cNomFic
    else
       ::cNomFic  := ""
    endif
RETURN ::cNomFic


*******************************************************************************
Function Evalua_bWhile( cReport )
return eval( &( cReport + "_bwhile" ) )

Function Evalua_bFor( cReport )
return eval( &( cReport + "_bFor" ) )




* Se declaran variables generales que se pueden necesitar en los reports
function variables( oFastReport )

   oFastReport:AddVariable("PRUEBAST","titulo"  ,"titulo" )

return nil

function cValtoChar( u ) ; return alltrim( CStr( u ) )