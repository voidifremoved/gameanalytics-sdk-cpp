#ifndef _GADEVICEIOS_H
#define _GADEVICEIOS_H

#include "GACommon.h"
#include <string>

#if IS_IOS

std::string getiOSVersion();
std::string getiOSConnectionType();
std::string getiOSDeviceModel();
int getiOSNumCpuCores();
int64_t getiOSTotalDeviceMemory();
std::string getiOSPersistentPath();

#endif

#endif
