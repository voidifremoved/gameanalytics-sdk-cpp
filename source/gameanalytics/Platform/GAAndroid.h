#pragma once

#include "Platform/GAPlatform.h"

#if IS_ANDROID

#include <signal.h>
#include <sys/types.h>
#include <sys/stat.h>

namespace gameanalytics
{
	class GAPlatformAndroid :
		public GAPlatform
	{
		public:

			std::string getOSVersion()			override;
			std::string getDeviceManufacturer() override;
			std::string getBuildPlatform()		override;
			std::string getPersistentPath()		override;
			std::string getDeviceModel()		override;

			virtual std::string getCpuModel() 			const override;
			virtual int 		getNumCpuCores() 		const override;
			virtual int64_t 	getTotalDeviceMemory() 	const override;

			virtual int64_t getAppMemoryUsage() const override;

			virtual int64_t getBootTime() const override;

			void setupUncaughtExceptionHandler() override;

			std::string getConnectionType() override;

			static void setWritablePath(const std::string& path);

		private:

			static std::string s_writablePath;
			static void signalHandler(int sig, siginfo_t* info, void* context);
	};
}

#endif
