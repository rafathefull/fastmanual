###############################################################################
# Written by Rafa Carmona
###############################################################################

# Make directives ##########################
.autodepend
.swap
.suffixes: .prg .hrb

#-------------------------------------------------------------------------
# Application directories & filenames
# Directorios principales
#-------------------------------------------------------------------------
APP_NAME        = test
HARBOUR_DIR    = \HARBOUR3
BORLANDC_DIR    = \FRONT32\BCC582
APP_PRG_DIR     = .
APP_OBJ_DIR     = .\o
APP_INCLUDE_DIR = \FRONT32\CLIP52\include
APP_EXE_DIR     = .
APP_RES_DIR     = RC

#-------------------------------------------------------------------------
# Rutinas 5
#-------------------------------------------------------------------------
RUTINAS_5  =  \FRONT32\CLIP52\RUTINAS5\UTILSH.LIB
#-------------------------------------------------------------------------

APP_EXE  = $(APP_EXE_DIR)\$(APP_NAME).exe
APP_RC   = $(APP_RES_DIR)\$(APP_NAME).rc
APP_RES  = $(APP_RES_DIR)\$(APP_NAME).res
APP_MAP  = $(APP_RES_DIR)\$(APP_NAME).map

# Paths for dependent files ###################
.path.prg = $(APP_PRG_DIR)
.path.hrb = $(APP_OBJ_DIR)
.path.o32 = $(APP_OBJ_DIR)

# Application PRG files (your PRG files go here) ###
APP_PRG_LIST = \
test.prg      \
fastmanual.prg \
FastRepH.prg \


# Contruction of the rest dependency lists #########
APP_PRGS = $(APP_PRG_LIST)
APP_HRBS = $(APP_PRG_LIST:.prg=.hrb)
APP_OBJS = $(APP_PRG_LIST:.prg=.o32)

# Harbour directories & Flags #############
HARBOUR_INCLUDE_DIR = $(HARBOUR_DIR)\include
HARBOUR_EXE_DIR     = $(HARBOUR_DIR)\bin\win\bcc
HARBOUR_LIB_DIR     = $(HARBOUR_DIR)\lib\win\bcc

#HARBOUR_INCLUDE_DIR = $(HARBOUR_DIR)\include
#HARBOUR_EXE_DIR     = $(HARBOUR_DIR)\bin
#HARBOUR_LIB_DIR     = $(HARBOUR_DIR)\lib

# ------------------------------
HARBOUR_FLAGS       = -i$(APP_INCLUDE_DIR);$(HARBOUR_INCLUDE_DIR); -n -w -m -d__HARBOUR__ -DHB_NO_TRACE 

# ------------------------------

# SOPORTE PARA HARBOUR 3.2, cambia llamada de SUPER a ::Super.
# ------------------------------
HARBOUR_FLAGS       = $( HARBOUR_FLAGS) -d__SUPER__


# ------------------------------
# Activarlo para Soporte de Profiler, version especial de Harbour
# ------------------------------
#APP_NAME        = HOT32_PROFILE
#HARBOUR_DIR     = \FRONT32\harbour_profile
#HARBOUR_FLAGS   = $( HARBOUR_FLAGS) -dPROFILER
#HARBOUR_INCLUDE_DIR = $(HARBOUR_DIR)\include
#HARBOUR_EXE_DIR     = $(HARBOUR_DIR)\BIN
#HARBOUR_LIB_DIR     = $(HARBOUR_DIR)\lib


# ---------------------------------
HARBOUR_EXE      = $(HARBOUR_EXE_DIR)\HARBOUR.EXE

# Harbour Libraries  #########################################################
RTL_LIB    = $(HARBOUR_LIB_DIR)\hbRTL.lib
VM_LIB     = $(HARBOUR_LIB_DIR)\hbVMMT.lib
GTWIN_LIB  = $(HARBOUR_LIB_DIR)\GTWIN.lib
GTGUI_LIB  = $(HARBOUR_LIB_DIR)\GTGUI.lib
GTWVT_LIB  = $(HARBOUR_LIB_DIR)\gtwvt.lib
GTWVG_LIB  = $(HARBOUR_LIB_DIR)\gtwvg.lib
PCREPOS_LIB= $(HARBOUR_LIB_DIR)\hbpcre.LIB
LANG_LIB   = $(HARBOUR_LIB_DIR)\hbLANG.lib
MACRO_LIB  = $(HARBOUR_LIB_DIR)\hbMACRO.lib
RDD_LIB    = $(HARBOUR_LIB_DIR)\hbRDD.lib
DBFNTX_LIB = $(HARBOUR_LIB_DIR)\rddntx.lib
COMMON_LIB = $(HARBOUR_LIB_DIR)\hbCOMMON.lib
PP_LIB     = $(HARBOUR_LIB_DIR)\hbPP.lib
CT_LIB     = $(HARBOUR_LIB_DIR)\hbct.lib
CODEPAGE_LIB  = $(HARBOUR_LIB_DIR)\hbcpage.lib
DEBUG_LIB  = $(HARBOUR_LIB_DIR)\hbdebug.lib
!ifndef PROFILER
OPT_LIB    = $(HARBOUR_LIB_DIR)\optgui.lib
!endif
DBFCDX_LIB = $(HARBOUR_LIB_DIR)\rddcdx.lib
FPT_LIB    = $(HARBOUR_LIB_DIR)\rddfpt.lib
HBSIX_LIB    = $(HARBOUR_LIB_DIR)\HBSIX.lib

# LIBRERIAS ADS  7
ADS_LIB   = $(HARBOUR_LIB_DIR)\rddads.lib
ADS32_LIB = $(HARBOUR_LIB_DIR)\ace32.lib

# LIBRERIAS ADS 9
#ADS_LIB   = $(HARBOUR_LIB_DIR)\rddads_9.lib
#ADS32_LIB = $(HARBOUR_LIB_DIR)\ace32_9.lib

WIN_LIB    = $(HARBOUR_LIB_DIR)\hbwin.lib
XHB_LIB    = $(HARBOUR_LIB_DIR)\xhb.lib
EXTERN_LIB = $(HARBOUR_LIB_DIR)\hbextern.lib

#Esta libreria, ws2_32.lib, es necesaria para usa HBTIP
TIP_LIB    = $(HARBOUR_LIB_DIR)\hbtip.lib
TIPSSL_LIB = $(HARBOUR_LIB_DIR)\hbtipssl.lib

GTWVT_LIB  = $(HARBOUR_LIB_DIR)\gtwvt.lib
GTWVG_LIB  = $(HARBOUR_LIB_DIR)\gtwvg.lib
HB_MISC_LIB  = $(HARBOUR_LIB_DIR)\hbmisc.lib

#SOPORTE PARA SSL
HBSSL_LIB   = $(HARBOUR_LIB_DIR)\hbssl.lib
HBEAY32_LIB = $(HARBOUR_LIB_DIR)\libeay32.lib
HBSSLEAY32_LIB = $(HARBOUR_LIB_DIR)\ssleay32.lib
HBSSLS_LIB  = $(HARBOUR_LIB_DIR)\hbssls.lib


# Borlanc directories & flags ################################################
BORLANDC_INCLUDE_DIR = $( BORLANDC_DIR )\INCLUDE
BORLANDC_EXE_DIR     = $( BORLANDC_DIR )\BIN
BORLANDC_LIB_DIR     = $( BORLANDC_DIR )\LIB
BORLANDC_COMP_FLAGS  = -c -O2 -I$(HARBOUR_INCLUDE_DIR);$(BORLANDC_INCLUDE_DIR)
BORLANDC_COMP_EXE    = $(BORLANDC_EXE_DIR)\BCC32.EXE


# ------------------------------
#Este muestra la consola, PARA DEBUG
# ------------------------------
BORLANDC_LINK_FLAGS  = -Gn -Tpe -s -I$(APP_OBJ_DIR) -x

# ------------------------------
#Este quita la consola
# ------------------------------
BORLANDC_LINK_FLAGS  = -aa -Gn -Tpe -s -I$(APP_OBJ_DIR) -x

BORLANDC_LINK_EXE    = $(BORLANDC_EXE_DIR)\ILINK32.EXE
BORLANDC_RES_EXE     = $(BORLANDC_EXE_DIR)\BRC32.EXE

# Borland libraries & files ##################################################
STARTUP_OBJ  = $(BORLANDC_LIB_DIR)\c0w32.obj
#CW32_LIB = $(BORLANDC_LIB_DIR)\CW32.lib
CW32_LIB = $(BORLANDC_LIB_DIR)\CW32mt.lib
IMPORT32_LIB = $(BORLANDC_LIB_DIR)\IMPORT32.lib

# Dependencies ##################################################
all: $(APP_OBJS) $(APP_HRBS) $(APP_EXE)

# Implicit Rules ##################################################
.prg.hrb:
   $(HARBOUR_EXE) $(HARBOUR_FLAGS) $** -o$@

.hrb.o32:
   $(BORLANDC_COMP_EXE) $(BORLANDC_COMP_FLAGS) -o$@ $**

$(APP_EXE) :: $(APP_OBJS)
   @echo $(STARTUP_OBJ) + > make.tmp
#   @echo $( RUTINAS_5 ) + >> make.tmp
   @echo $(**), + >> make.tmp
   @echo $(APP_EXE), + >> make.tmp
   @echo $(APP_MAP), + >> make.tmp
# La declaracion de OPT_LIB debe de ser ANTES de la RTL, pero debemos desactivar SI queremos PROFILER
#   @echo $( OPT_LIB ) + >> make.tmp
   @echo $( RUTINAS_5 ) + >> make.tmp
   @echo $( HB_ADO_LIB ) + >> make.tmp
   @echo $( TIPSSL_LIB ) + >> make.tmp
   @echo $( XHB_LIB ) + >> make.tmp
   @echo $( CODEPAGE_LIB ) + >> make.tmp
   @echo $( DEBUG_LIB ) + >> make.tmp
   @echo $( RTL_LIB ) + >> make.tmp
   @echo $( VM_LIB )  + >> make.tmp
   @echo $( HB_HTTP_LIB ) + >> make.tmp
   @echo $( HBSSLS_LIB  ) + >> make.tmp
   @echo $( HBSSL_LIB    ) + >> make.tmp
   @echo $( HBSSLEAY32_LIB  ) + >> make.tmp
   @echo $( HBEAY32_LIB  ) + >> make.tmp
   @echo $( EXTERN_LIB   ) + >> make.tmp
   @echo $( WIN_LIB ) + >> make.tmp
   @echo $( GTWVT_LIB ) + >> make.tmp
   @echo $( GTWVG_LIB ) + >> make.tmp
   @echo $( GTWIN_LIB ) + >> make.tmp
   @echo $( GTGUI_LIB ) + >> make.tmp
   @echo $( PCREPOS_LIB ) + >> make.tmp
   @echo $( LANG_LIB ) + >> make.tmp
   @echo $( MACRO_LIB ) + >> make.tmp
   @echo $( RDD_LIB ) + >> make.tmp
   @echo $( DBFNTX_LIB ) + >> make.tmp
   @echo $( HBSIX_LIB) + >> make.tmp
   @echo $( DBFCDX_LIB ) + >> make.tmp
   @echo $( FPT_LIB ) + >> make.tmp
   @echo $( COMMON_LIB ) + >> make.tmp
   @echo $( HB_MISC_LIB ) + >> make.tmp
   @echo $( PP_LIB ) + >> make.tmp
   @echo $( CT_LIB ) + >> make.tmp
   @echo $( DEBUG_LIB ) + >> make.tmp
   @echo $( CW32_LIB ) + >> make.tmp
   @echo $( IMPORT32_LIB ) + >> make.tmp
   @echo $( HB_CURL_LIB ) + >> make.tmp
   @echo $( CURL_LIB ) + >> make.tmp
   @echo $( ADS_LIB ) + >> make.tmp
   @echo $( ADS32_LIB ) + >> make.tmp
   @echo $(BORLANDC_LIB_DIR)\cw32.lib + >> make.tmp
   @echo $(BORLANDC_LIB_DIR)\import32.lib + >> make.tmp
   @echo $(BORLANDC_LIB_DIR)\psdk\ws2_32.lib + >> make.tmp
   @echo $(BORLANDC_LIB_DIR)\psdk\odbc32.lib + >> make.tmp
   @echo $(BORLANDC_LIB_DIR)\psdk\nddeapi.lib + >> make.tmp
   @echo $(BORLANDC_LIB_DIR)\psdk\iphlpapi.lib + >> make.tmp
   @echo $(BORLANDC_LIB_DIR)\psdk\msimg32.lib + >> make.tmp
   @echo $(BORLANDC_LIB_DIR)\psdk\rasapi32.lib >> make.tmp
   $(BORLANDC_LINK_EXE) $(BORLANDC_LINK_FLAGS) @make.tmp
   @del $(APP_EXE_DIR)\$(APP_NAME).tds
  # del make.tmp

