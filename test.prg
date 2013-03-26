/*
  
  Ejemplo de como podemos controlar un bWhile y bFor dentro de FastReport
  ( c )2013
*/

FUNCTION Main()
LOCAL fdesde := CTOD("01/01/2013")
LOCAL fhasta := date()+1
LOCAL cCodigo := "G"
LOCAL cTexto := "*GENERAL*"
Local FrPrn
lOCAL oFast

Local bStart :=  {|| dtos(fdesde) }
Local bWhile :=  {|| librorec->fecha <= fhasta }
Local bFor   :=  {|| librorec->usuario = cTexto  }

    SetMode( 25,80)
    set path to ".\"
    PUBLIC CODUSU := "test"

    oFast := TFastManual():New( "LLIBRO", bStart, bWhile, bFor ) 

        // oFast:SetPrinter( cPrinter )  // Si pasamos impresora
        oFast:SetDesign( .F. )   // Si queremos que entre en modo diseño
        oFast:SetTitle( "Titulo" )       // Titulo 
        // oFast:SetDirect( lDirecto )   // Si queremos que imprima directo por impresora sin preview
        // oFast:OutputFile( cNomFic )   // Si indicamos fichero con extension, TXT, PDF o HTML

     oFast:Run()


RETURN 0
