##### Project #####

PY32F0_TEMPLATE	?= py32f0-project/

PROJECT			?= hello-world
# The path for generated files
BUILD_DIR		= Build

MCU_TYPE		= PY32F002Ax5

##### Options #####

# Use LL library instead of HAL, y:yes, n:no
USE_LL_LIB ?= n
# Enable printf float %f support, y:yes, n:no
ENABLE_PRINTF_FLOAT	?= n
# Build with FreeRTOS, y:yes, n:no
USE_FREERTOS	?= n
# Build with CMSIS DSP functions, y:yes, n:no
USE_DSP			?= n
# Build with Waveshare e-paper lib, y:yes, n:no
USE_EPAPER		?= n
# Programmer, jlink or pyocd
FLASH_PROGRM	?= pyocd

##### Toolchains #######

ARM_TOOLCHAIN	?= /usr/bin

# path to JLinkExe
JLINKEXE		?= /opt/SEGGER/JLink/JLinkExe
# path to PyOCD
PYOCD_EXE		?= pyocd

##### Paths ############

# C and CPP source folders
CDIRS		:= hello-world
# Single C and CPP source files
CFILES		:= 
CPPFILES	:= 

# ASM source folders
ADIRS		:= hello-world
# Single ASM source files
AFILES		:= 

# Include paths
INCLUDES	:= $(PY32F0_TEMPLATE)Libraries/CMSIS/Core/Include \
			$(PY32F0_TEMPLATE)Libraries/CMSIS/Device/PY32F0xx/Include \
			$(CDIRS)

##### Library Paths ############

# Library flags
LIB_FLAGS		= $(MCU_TYPE)
# JLink device (Uppercases)
JLINK_DEVICE	?= $(shell echo $(MCU_TYPE) | tr '[:lower:]' '[:upper:]')
# PyOCD device (Lowercases)
PYOCD_DEVICE	?= $(shell echo $(MCU_TYPE) | tr '[:upper:]' '[:lower:]')
# Link descript file: 
LDSCRIPT		= py32f002ax5-baofeng-app.ld


# PY32F002A,003,030 >>>
CFILES		+= $(PY32F0_TEMPLATE)Libraries/CMSIS/Device/PY32F0xx/Source/system_py32f0xx.c

ifeq ($(USE_LL_LIB),y)
CDIRS		+= $(PY32F0_TEMPLATE)Libraries/PY32F0xx_LL_Driver/Src \
		$(PY32F0_TEMPLATE)Libraries/PY32F0xx_LL_BSP/Src
INCLUDES	+= $(PY32F0_TEMPLATE)Libraries/PY32F0xx_LL_Driver/Inc \
		$(PY32F0_TEMPLATE)Libraries/PY32F0xx_LL_BSP/Inc
LIB_FLAGS   += USE_FULL_LL_DRIVER
else
CDIRS		+= $(PY32F0_TEMPLATE)Libraries/PY32F0xx_HAL_Driver/Src \
		$(PY32F0_TEMPLATE)Libraries/PY32F0xx_HAL_BSP/Src
INCLUDES	+= $(PY32F0_TEMPLATE)Libraries/PY32F0xx_HAL_Driver/Inc \
		$(PY32F0_TEMPLATE)Libraries/PY32F0xx_HAL_BSP/Inc
endif
# Startup file
ifneq (,$(findstring PY32F002A,$(LIB_FLAGS)))
AFILES	:= $(PY32F0_TEMPLATE)Libraries/CMSIS/Device/PY32F0xx/Source/gcc/startup_py32f002a.s
endif
# PY32F002A,003,030 <<<


######## Additional Libs ########

ifeq ($(USE_FREERTOS),y)
CDIRS		+= $(PY32F0_TEMPLATE)Libraries/FreeRTOS \
			$(PY32F0_TEMPLATE)Libraries/FreeRTOS/portable/GCC/ARM_CM0

CFILES		+= $(PY32F0_TEMPLATE)Libraries/FreeRTOS/portable/MemMang/heap_4.c

INCLUDES	+= $(PY32F0_TEMPLATE)Libraries/FreeRTOS/include \
			$(PY32F0_TEMPLATE)Libraries/FreeRTOS/portable/GCC/ARM_CM0
endif

ifeq ($(USE_DSP),y)
CFILES 		+= $(PY32F0_TEMPLATE)Libraries/CMSIS/DSP/Source/BasicMathFunctions/BasicMathFunctions.c \
		$(PY32F0_TEMPLATE)Libraries/CMSIS/DSP/Source/BayesFunctions/BayesFunctions.c \
		$(PY32F0_TEMPLATE)Libraries/CMSIS/DSP/Source/CommonTables/CommonTables.c \
		$(PY32F0_TEMPLATE)Libraries/CMSIS/DSP/Source/ComplexMathFunctions/ComplexMathFunctions.c \
		$(PY32F0_TEMPLATE)Libraries/CMSIS/DSP/Source/ControllerFunctions/ControllerFunctions.c \
		$(PY32F0_TEMPLATE)Libraries/CMSIS/DSP/Source/DistanceFunctions/DistanceFunctions.c \
		$(PY32F0_TEMPLATE)Libraries/CMSIS/DSP/Source/FastMathFunctions/FastMathFunctions.c \
		$(PY32F0_TEMPLATE)Libraries/CMSIS/DSP/Source/FilteringFunctions/FilteringFunctions.c \
		$(PY32F0_TEMPLATE)Libraries/CMSIS/DSP/Source/InterpolationFunctions/InterpolationFunctions.c \
		$(PY32F0_TEMPLATE)Libraries/CMSIS/DSP/Source/MatrixFunctions/MatrixFunctions.c \
		$(PY32F0_TEMPLATE)Libraries/CMSIS/DSP/Source/QuaternionMathFunctions/QuaternionMathFunctions.c \
		$(PY32F0_TEMPLATE)Libraries/CMSIS/DSP/Source/StatisticsFunctions/StatisticsFunctions.c \
		$(PY32F0_TEMPLATE)Libraries/CMSIS/DSP/Source/SupportFunctions/SupportFunctions.c \
		$(PY32F0_TEMPLATE)Libraries/CMSIS/DSP/Source/SVMFunctions/SVMFunctions.c \
		$(PY32F0_TEMPLATE)Libraries/CMSIS/DSP/Source/TransformFunctions/TransformFunctions.c
INCLUDES	+= $(PY32F0_TEMPLATE)Libraries/CMSIS/DSP/Include \
		$(PY32F0_TEMPLATE)Libraries/CMSIS/DSP/PrivateInclude
endif

ifeq ($(USE_EPAPER),y)
CDIRS		+= $(PY32F0_TEMPLATE)Libraries/EPaper/Lib \
			$(PY32F0_TEMPLATE)Libraries/EPaper/Examples \
			$(PY32F0_TEMPLATE)Libraries/EPaper/Fonts \
			$(PY32F0_TEMPLATE)Libraries/EPaper/GUI

INCLUDES	+= $(PY32F0_TEMPLATE)Libraries/EPaper/Lib \
			$(PY32F0_TEMPLATE)Libraries/EPaper/Examples \
			$(PY32F0_TEMPLATE)Libraries/EPaper/Fonts \
			$(PY32F0_TEMPLATE)Libraries/EPaper/GUI
endif

include $(PY32F0_TEMPLATE)rules.mk
