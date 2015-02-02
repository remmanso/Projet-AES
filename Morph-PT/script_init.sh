############### ISE v12.2

PLATFORM=lin
export PRINTER=ocaeimp
XILINX=/softslin/ise_edk_122i/ISE
export XILINX

KERNEL=`uname -a | grep 2.6.29-2-amd64`
if [  -n "$KERNEL" ]; then
        echo "Debian 64 bit"
else
echo ""
echo ""
echo "  ****      ****    *   *  *****    ****    ***"
echo "  *         *       **  *    *      *  *   *  "
echo "  *         ***     * * *    *      *  *    **"
echo "  *         *       *  **    *      *  *      *"
echo "  ****      ****    *   *    *      ****   **"
echo ""
echo ""
fi


LM_LICENSE_FILE=2110@cimekey1
export LM_LICENSE_FILE
export XILINXD_LICENSE_FILE=${LM_LICENSE_FILE}

if [ -n "$LMC_HOME" ]
then
   LMC_HOME=${XILINX}/smartmodel/${PLATFORM}/installed_lin:${LMC_HOME}
else
   LMC_HOME=${XILINX}/smartmodel/${PLATFORM}/installed_lin
fi
export LMC_HOME

if [ -n "$PATH" ]
then
   PATH=${XILINX}/bin/${PLATFORM}:${PATH}
else
   PATH=${XILINX}/bin/${PLATFORM}
fi
export PATH

if [ -n "$LD_LIBRARY_PATH" ]
then
   LD_LIBRARY_PATH=${XILINX}/bin/${PLATFORM}:/usr/X11R6/lib:${LD_LIBRARY_PATH}
else
   LD_LIBRARY_PATH=${XILINX}/bin/${PLATFORM}:/usr/X11R6/lib
fi
export LD_LIBRARY_PATH

if [ -n "$NPX_PLUGIN_PATH" ]
then
   NPX_PLUGIN_PATH=${XILINX}/java/${PLATFORM}/jre/plugin/i386/ns4:${NPX_PLUGIN_PATH}
else
   NPX_PLUGIN_PATH=${XILINX}/java/${PLATFORM}/jre/plugin/i386/ns4
fi
export NPX_PLUGIN_PATH

myxilinxrc=${HOME}/.qt/xilinxrc

if [ -d "${SYSCONF}/xilinxrc" -a ! -f "$myxilinxrc" ]
then cp "${SYSCONF}/xilinxrc" "$myxilinxrc"
elif [ -f "/Xilinx/xilinxrc" -a ! -f "$myxilinxrc" ]
then cp "/Xilinx/xilinxrc" "$myxilinxrc"
fi

#####################
######### EDK v12.2


PLATFORM=lin
export PRINTER=ocaeimp
XILINX_EDK=/softslin/ise_edk_122i/EDK
export XILINX_EDK


if [ -n "$LMC_HOME" ]
then
   LMC_HOME=${XILINX_EDK}/smartmodel/${PLATFORM}/installed_lin:${LMC_HOME}
else
   LMC_HOME=${XILINX_EDK}/smartmodel/${PLATFORM}/installed_lin
fi
export LMC_HOME

if [ -n "$PATH" ]
then
   PATH=${XILINX_EDK}/bin/${PLATFORM}:${XILINX_EDK}/gnu/powerpc-eabi/lin/bin/:${PATH}
else
   PATH=${XILINX_EDK}/bin/${PLATFORM}:${XILINX_EDK}/gnu/powerpc-eabi/lin/bin/
fi
export PATH

if [ -n "$LD_LIBRARY_PATH" ]
then
   LD_LIBRARY_PATH=${XILINX_EDK}/bin/${PLATFORM}:${XILINX_EDK}/lib/${PLATFORM}:/usr/X11R6/lib:${LD_LIBRARY_PATH}
else
   LD_LIBRARY_PATH=${XILINX_EDK}/bin/${PLATFORM}:${XILINX_EDK}/lib/${PLATFORM}:/usr/X11R6/lib
fi
export LD_LIBRARY_PATH

if [ -n "$NPX_PLUGIN_PATH" ]
then
   NPX_PLUGIN_PATH=${XILINX_EDK}/java/${PLATFORM}/jre/plugin/i386/ns4:${NPX_PLUGIN_PATH}
else
   NPX_PLUGIN_PATH=${XILINX_EDK}/java/${PLATFORM}/jre/plugin/i386/ns4
fi
export NPX_PLUGIN_PATH

myxilinxrc=${HOME}/.qt/xilinxrc

if [ -d "${SYSCONF}/xilinxrc" -a ! -f "$myxilinxrc" ]
then cp "${SYSCONF}/xilinxrc" "$myxilinxrc"
elif [ -f "/Xilinx/xilinxrc" -a ! -f "$myxilinxrc" ]
then cp "/Xilinx/xilinxrc" "$myxilinxrc"
fi

#######################
####### modelsim v6.5d
#!/bin/bash
#
# MENTOR GRAPHICS ModelSim version 6.5d in native environement
#


export MTI_HOME=/softslin/modelsim6_5d/modeltech
export PATH="$PATH:$MTI_HOME/`$MTI_HOME/vco`"

if [ -n "${LM_LICENSE_FILE}" ] ; then
    export LM_LICENSE_FILE="${LM_LICENSE_FILE}:1718@cimekey1"
else
    export LM_LICENSE_FILE="1718@cimekey1"
fi

export MODEL_TECH="/softslin/modelsim6_5d/modeltech/linux"
export MODELSIM="$HOME/Documents/Projet_AES/Morph-PT/modelsim.ini"

