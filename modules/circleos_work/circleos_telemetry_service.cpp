// circleos_telemetry_service.cpp
// CircleOS Telemetry Service — SA:65545
// Collects boot timing + SA "up" counts and writes them to circleos.telemetry.* params.
// Self-contained inline class, registered via REGISTER_SYSTEM_ABILITY_BY_ID.

#include <atomic>
#include <chrono>
#include <cstdio>
#include <cstdlib>
#include <ctime>
#include <fstream>
#include <sstream>
#include <string>
#include <thread>
#include <vector>

#include "hilog/log.h"
#include "iremote_object.h"
#include "parameter.h"
#include "parameters.h"
#include "system_ability.h"
#include "system_ability_definition.h"

namespace OHOS {
namespace CircleOS {

namespace {
constexpr int32_t CIRCLEOS_TELEMETRY_SA_ID = 65545;
constexpr OHOS::HiviewDFX::HiLogLabel LABEL = {LOG_CORE, 0xD0AA009, "CircleTelemetry"};
constexpr int kCollectIntervalSec = 30;

const std::vector<std::string> kTrackedSAStateKeys = {
    "circleos.privacy.state",
    "circleos.network.state",
    "circleos.identity.state",
    "circleos.storage.state",
    "circleos.push.state",
    "circleos.butler.state",
    "circleos.payment.state",
    "circleos.aether.state",
};

double ReadUptimeSeconds() {
    std::ifstream f("/proc/uptime");
    if (!f.is_open()) {
        return -1.0;
    }
    double up = -1.0;
    f >> up;
    return up;
}

int CountSAsUp() {
    int up = 0;
    for (const auto& key : kTrackedSAStateKeys) {
        std::string v = OHOS::system::GetParameter(key, "");
        if (!v.empty() && v != "stopped") {
            up++;
        }
    }
    return up;
}

std::string FormatDouble(double d) {
    char buf[64];
    std::snprintf(buf, sizeof(buf), "%.3f", d);
    return std::string(buf);
}

std::string NowEpochString() {
    auto now = std::chrono::system_clock::now();
    auto secs = std::chrono::duration_cast<std::chrono::seconds>(
        now.time_since_epoch()).count();
    return std::to_string(secs);
}
}  // namespace

class CircleOSTelemetryService : public SystemAbility {
    DECLARE_SYSTEM_ABILITY(CircleOSTelemetryService);

public:
    CircleOSTelemetryService(int32_t saId, bool runOnCreate)
        : SystemAbility(saId, runOnCreate) {}
    ~CircleOSTelemetryService() override {
        running_.store(false);
    }

    void OnStart() override {
        OHOS::HiviewDFX::HiLog::Info(LABEL, "CircleOSTelemetryService OnStart");
        OHOS::system::SetParameter("circleos.telemetry.state", "starting");

        // Initial snapshot — synchronous
        CollectOnce("boot");

        // Background refresh loop — detached, errors caught and logged
        running_.store(true);
        std::thread([this]() {
            while (running_.load()) {
                try {
                    std::this_thread::sleep_for(
                        std::chrono::seconds(kCollectIntervalSec));
                    if (!running_.load()) break;
                    CollectOnce("periodic");
                } catch (const std::exception& e) {
                    OHOS::HiviewDFX::HiLog::Error(
                        LABEL, "telemetry watcher exception: %{public}s", e.what());
                } catch (...) {
                    OHOS::HiviewDFX::HiLog::Error(
                        LABEL, "telemetry watcher unknown exception");
                }
            }
        }).detach();

        OHOS::system::SetParameter("circleos.telemetry.state", "running");
        OHOS::HiviewDFX::HiLog::Info(LABEL, "CircleOSTelemetryService started");
    }

    void OnStop() override {
        OHOS::HiviewDFX::HiLog::Info(LABEL, "CircleOSTelemetryService OnStop");
        running_.store(false);
        OHOS::system::SetParameter("circleos.telemetry.state", "stopped");
    }

private:
    void CollectOnce(const char* phase) {
        try {
            double up = ReadUptimeSeconds();
            int saUp = CountSAsUp();
            std::string epoch = NowEpochString();

            if (up >= 0.0) {
                OHOS::system::SetParameter(
                    "circleos.telemetry.boot_seconds", FormatDouble(up));
            }
            OHOS::system::SetParameter(
                "circleos.telemetry.sa_up_count", std::to_string(saUp));
            OHOS::system::SetParameter(
                "circleos.telemetry.collected_at", epoch);

            OHOS::HiviewDFX::HiLog::Info(
                LABEL,
                "telemetry %{public}s: boot=%{public}.3f sa_up=%{public}d at=%{public}s",
                phase, up, saUp, epoch.c_str());
        } catch (const std::exception& e) {
            OHOS::HiviewDFX::HiLog::Error(
                LABEL, "CollectOnce exception: %{public}s", e.what());
        } catch (...) {
            OHOS::HiviewDFX::HiLog::Error(
                LABEL, "CollectOnce unknown exception");
        }
    }

    std::atomic<bool> running_{false};
};

REGISTER_SYSTEM_ABILITY_BY_ID(
    CircleOSTelemetryService, CIRCLEOS_TELEMETRY_SA_ID, true);

}  // namespace CircleOS
}  // namespace OHOS
