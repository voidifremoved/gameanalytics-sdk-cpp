#include "GAAndroid.h"

#if IS_ANDROID

#include "GAState.h"
#include "GAEvents.h"

#include <sys/sysctl.h>
#include <sys/utsname.h>
#include <sys/sysinfo.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fstream>
#include <sstream>
#include <ctime>

#include <sys/system_properties.h>

static struct sigaction prevSigAction;

std::string gameanalytics::GAPlatformAndroid::s_writablePath;

static std::string getSystemProperty(const char* name)
{
    char value[PROP_VALUE_MAX] = {0};
    __system_property_get(name, value);
    return std::string(value);
}

std::string gameanalytics::GAPlatformAndroid::getOSVersion()
{
    std::string version = getSystemProperty("ro.build.version.release");
    return getBuildPlatform() + " " + version;
}

std::string gameanalytics::GAPlatformAndroid::getDeviceManufacturer()
{
    return getSystemProperty("ro.product.manufacturer");
}

std::string gameanalytics::GAPlatformAndroid::getBuildPlatform()
{
    return "android";
}

std::string gameanalytics::GAPlatformAndroid::getConnectionType()
{
    return CONNECTION_LAN;
}

std::string gameanalytics::GAPlatformAndroid::getPersistentPath()
{
    if (!s_writablePath.empty())
    {
        std::string path = s_writablePath + "/GameAnalytics";
        if (!std::filesystem::exists(path))
        {
            std::filesystem::create_directories(path);
        }
        return path;
    }

    std::string path = "/data/local/tmp/GameAnalytics";
    if (!std::filesystem::exists(path))
    {
        std::filesystem::create_directories(path);
    }
    return path;
}

std::string gameanalytics::GAPlatformAndroid::getDeviceModel()
{
    return getSystemProperty("ro.product.model");
}

void gameanalytics::GAPlatformAndroid::setWritablePath(const std::string& path)
{
    s_writablePath = path;
}

void gameanalytics::GAPlatformAndroid::setupUncaughtExceptionHandler()
{
    struct sigaction mySigAction;
    mySigAction.sa_sigaction = signalHandler;
    mySigAction.sa_flags = SA_SIGINFO;

    sigemptyset(&mySigAction.sa_mask);

    int signals[] = {SIGQUIT, SIGILL, SIGTRAP, SIGABRT, SIGFPE, SIGBUS, SIGSEGV, SIGSYS, SIGPIPE, SIGALRM, SIGXCPU, SIGXFSZ};
    for (int sig : signals)
    {
        sigaction(sig, NULL, &prevSigAction);
        if (prevSigAction.sa_handler != SIG_IGN)
        {
            sigaction(sig, &mySigAction, NULL);
        }
    }
}

void gameanalytics::GAPlatformAndroid::signalHandler(int sig, siginfo_t* info, void* context)
{
    static int errorCount = 0;

    if (state::GAState::useErrorReporting())
    {
        std::string stackTrace = "Signal caught: " + std::to_string(sig) + "\n";

        if (errorCount <= MAX_ERROR_TYPE_COUNT)
        {
            errorCount++;
            events::GAEvents::addErrorEvent(EGAErrorSeverity::Critical, stackTrace, "", -1, {}, false, false);
            events::GAEvents::processEvents("error", false);
        }

        struct sigaction newact;
        newact.sa_flags = 0;
        sigemptyset(&newact.sa_mask);
        newact.sa_handler = SIG_DFL;
    }

    if (*prevSigAction.sa_handler != NULL)
    {
        (*prevSigAction.sa_handler)(sig);
    }
}

std::string gameanalytics::GAPlatformAndroid::getCpuModel() const
{
    std::ifstream cpuinfo("/proc/cpuinfo");
    std::string line;
    while (std::getline(cpuinfo, line))
    {
        if (line.find("Hardware") != std::string::npos ||
            line.find("model name") != std::string::npos)
        {
            auto pos = line.find(':');
            if (pos != std::string::npos && pos + 2 < line.size())
            {
                return line.substr(pos + 2);
            }
        }
    }

    struct utsname systemInfo;
    uname(&systemInfo);
    return systemInfo.machine;
}

int gameanalytics::GAPlatformAndroid::getNumCpuCores() const
{
    return static_cast<int>(sysconf(_SC_NPROCESSORS_ONLN));
}

int64_t gameanalytics::GAPlatformAndroid::getTotalDeviceMemory() const
{
    struct sysinfo info;
    if (sysinfo(&info) == 0)
    {
        return utilities::convertBytesToMB(static_cast<int64_t>(info.totalram) * info.mem_unit);
    }
    return -1;
}

int64_t gameanalytics::GAPlatformAndroid::getAppMemoryUsage() const
{
    std::ifstream statusFile("/proc/self/status");
    std::string line;
    while (std::getline(statusFile, line))
    {
        if (line.find("VmRSS:") != std::string::npos)
        {
            std::istringstream iss(line);
            std::string label;
            int64_t value;
            iss >> label >> value;
            return value / 1024; // KB to MB
        }
    }
    return 0;
}

int64_t gameanalytics::GAPlatformAndroid::getBootTime() const
{
    struct timespec ts;
    if (clock_gettime(CLOCK_MONOTONIC, &ts) == 0)
    {
        return ts.tv_sec * 1000 + ts.tv_nsec / 1000000;
    }
    return -1;
}

#endif
