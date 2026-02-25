#include "GAiOS.h"

#if IS_IOS

#include "GADeviceiOS.h"
#include "GAState.h"
#include "GAEvents.h"

#include <execinfo.h>
#include <sys/sysctl.h>
#include <sys/utsname.h>
#include <mach/mach.h>
#include <sys/stat.h>
#include <unistd.h>

static struct sigaction prevSigAction;

std::string gameanalytics::GAPlatformiOS::getOSVersion()
{
    std::string iosVersion = getiOSVersion();
    return getBuildPlatform() + " " + iosVersion;
}

std::string gameanalytics::GAPlatformiOS::getDeviceManufacturer()
{
    return "Apple";
}

std::string gameanalytics::GAPlatformiOS::getBuildPlatform()
{
    return "ios";
}

std::string gameanalytics::GAPlatformiOS::getConnectionType()
{
    return getiOSConnectionType();
}

std::string gameanalytics::GAPlatformiOS::getPersistentPath()
{
    return getiOSPersistentPath();
}

std::string gameanalytics::GAPlatformiOS::getDeviceModel()
{
    return getiOSDeviceModel();
}

void gameanalytics::GAPlatformiOS::setupUncaughtExceptionHandler()
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

void gameanalytics::GAPlatformiOS::signalHandler(int sig, siginfo_t* info, void* context)
{
    constexpr int NUM_MAX_FRAMES = 128;
    static int errorCount = 0;

    if (state::GAState::useErrorReporting())
    {
        void* frames[NUM_MAX_FRAMES];
        int len = backtrace(frames, NUM_MAX_FRAMES);
        char** symbols = backtrace_symbols(frames, len);

        std::string stackTrace = "Stack trace:\n";
        for (int i = 0; i < len; ++i)
        {
            stackTrace += symbols[i];
            stackTrace += '\n';
        }

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

std::string gameanalytics::GAPlatformiOS::getCpuModel() const
{
    struct utsname systemInfo;
    uname(&systemInfo);
    return systemInfo.machine;
}

int gameanalytics::GAPlatformiOS::getNumCpuCores() const
{
    return getiOSNumCpuCores();
}

int64_t gameanalytics::GAPlatformiOS::getTotalDeviceMemory() const
{
    return utilities::convertBytesToMB(getiOSTotalDeviceMemory());
}

int64_t gameanalytics::GAPlatformiOS::getAppMemoryUsage() const
{
    struct task_basic_info info;
    mach_msg_type_number_t infoSize = TASK_BASIC_INFO_COUNT;
    kern_return_t result = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&info, &infoSize);

    if (result == KERN_SUCCESS)
    {
        return utilities::convertBytesToMB(info.resident_size);
    }

    return 0;
}

int64_t gameanalytics::GAPlatformiOS::getSysMemoryUsage() const
{
    mach_port_t port = mach_host_self();
    mach_msg_type_number_t hostSize = sizeof(vm_statistics_data_t) / sizeof(integer_t);

    vm_size_t pageSize;
    host_page_size(port, &pageSize);

    vm_statistics_data_t stats;

    if (host_statistics(port, HOST_VM_INFO, (host_info_t)&stats, &hostSize) == KERN_SUCCESS)
    {
        const int64_t freeMemory = (stats.free_count + stats.inactive_count) * pageSize;
        return getTotalDeviceMemory() - utilities::convertBytesToMB(freeMemory);
    }

    return 0;
}

int64_t gameanalytics::GAPlatformiOS::getBootTime() const
{
    const size_t len = 4;
    int mib[len] = {0, 0, 0, 0};
    struct kinfo_proc kp = {};

    const size_t pidId = 3;

    size_t num = len;
    sysctlnametomib("kern.proc.pid", mib, &num);
    mib[pidId] = getpid();

    num = sizeof(kp);
    sysctl(mib, len, &kp, &num, NULL, 0);

    struct timeval startTime = kp.kp_proc.p_un.__p_starttime;
    struct timeval currentTime = {};

    gettimeofday(&currentTime, NULL);

    int64_t remainingMs = static_cast<double>(currentTime.tv_usec - startTime.tv_usec) * 1e-3;
    return (currentTime.tv_sec - startTime.tv_sec) * 1000 + remainingMs;
}

#endif
