// circleos_launcher / main.cpp
// Native CLI menu binary for CircleOS smoke testing.
// Reads/writes circleos.* params via init/begetutil. No GUI, no curses, plain iostream.

#include <chrono>
#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <thread>

#include "parameter.h"
#include "parameters.h"

namespace {

constexpr const char* kVersion = "v0.1";
constexpr const char* kPeersJsonPath =
    "/data/service/el1/public/circleos_aether/peers.json";

std::string GetParam(const std::string& key, const std::string& def = "") {
    return OHOS::system::GetParameter(key, def);
}

void SetParam(const std::string& key, const std::string& value) {
    OHOS::system::SetParameter(key, value);
}

void Sleep(int seconds) {
    std::this_thread::sleep_for(std::chrono::seconds(seconds));
}

std::string Trim(const std::string& s) {
    size_t a = s.find_first_not_of(" \t\r\n");
    if (a == std::string::npos) return "";
    size_t b = s.find_last_not_of(" \t\r\n");
    return s.substr(a, b - a + 1);
}

void PrintBanner() {
    std::string boot   = GetParam("circleos.telemetry.boot_seconds", "?");
    std::string saUp   = GetParam("circleos.telemetry.sa_up_count", "?");
    std::string peers  = GetParam("circleos.aether.peer_count", "0");
    std::string wallet = GetParam("circleos.payment.address", "(unbound)");
    std::string bal    = GetParam("circleos.payment.balance_display", "0");

    std::cout << "\n";
    std::cout << "+---------------------------------------+\n";
    std::cout << "|          CircleOS " << kVersion << "                |\n";
    std::cout << "|  Boot:  " << boot   << "s\n";
    std::cout << "|  SAs:   " << saUp   << "/8\n";
    std::cout << "|  Peers: " << peers  << " nearby\n";
    std::cout << "|  Wallet:" << wallet << "\n";
    std::cout << "|  Bal:   " << bal    << "\n";
    std::cout << "+---------------------------------------+\n";
}

void PrintMenu() {
    std::cout << "\n";
    std::cout << "  1) Refresh status\n";
    std::cout << "  2) Send test payment\n";
    std::cout << "  3) Send \"Hey B\" intent\n";
    std::cout << "  4) Push test notification\n";
    std::cout << "  5) List mesh peers\n";
    std::cout << "  6) Exit\n";
    std::cout << "\nSelect: " << std::flush;
}

std::string PromptLine(const std::string& label) {
    std::cout << label << std::flush;
    std::string s;
    if (!std::getline(std::cin, s)) {
        return "";
    }
    return Trim(s);
}

void OptRefresh() {
    std::cout << "\n[Refreshing status from params...]\n";
    PrintBanner();
}

void OptTestPayment() {
    std::string to = PromptLine("  to-address: ");
    if (to.empty()) {
        std::cout << "  (cancelled - empty address)\n";
        return;
    }
    std::string amt = PromptLine("  amount (cents): ");
    if (amt.empty()) {
        std::cout << "  (cancelled - empty amount)\n";
        return;
    }
    std::string payload = to + ":" + amt;
    std::cout << "  -> circleos.payment.test_send = " << payload << "\n";
    SetParam("circleos.payment.test_send", payload);

    std::cout << "  (waiting 3s for SA to process)\n";
    Sleep(3);

    std::cout << "  last_result : "
              << GetParam("circleos.payment.last_result", "(none)") << "\n";
    std::cout << "  last_txid   : "
              << GetParam("circleos.payment.last_txid", "(none)") << "\n";
    std::cout << "  balance     : "
              << GetParam("circleos.payment.balance_display", "(none)") << "\n";
}

void OptHeyB() {
    std::string text = PromptLine("  intent text: ");
    if (text.empty()) {
        std::cout << "  (cancelled - empty intent)\n";
        return;
    }
    std::cout << "  -> circleos.butler.test_intent = " << text << "\n";
    SetParam("circleos.butler.test_intent", text);

    std::cout << "  (waiting 3s for Butler to route)\n";
    Sleep(3);

    std::cout << "  last_intent  : "
              << GetParam("circleos.butler.last_intent", "(none)") << "\n";
    std::cout << "  last_sa      : "
              << GetParam("circleos.butler.last_sa", "(none)") << "\n";
    std::cout << "  last_response: "
              << GetParam("circleos.butler.last_response", "(none)") << "\n";
}

void OptPushTest() {
    std::string text = PromptLine("  notification text: ");
    if (text.empty()) {
        std::cout << "  (cancelled - empty text)\n";
        return;
    }
    std::cout << "  -> circleos.push.test_enqueue = " << text << "\n";
    SetParam("circleos.push.test_enqueue", text);

    std::cout << "  (waiting 3s for push SA to process)\n";
    Sleep(3);

    std::cout << "  pending_count: "
              << GetParam("circleos.push.pending_count", "(none)") << "\n";
    std::cout << "  last_enqueued: "
              << GetParam("circleos.push.last_enqueued", "(none)") << "\n";
}

void OptListPeers() {
    std::cout << "  peer_count: "
              << GetParam("circleos.aether.peer_count", "0") << "\n";
    std::ifstream f(kPeersJsonPath);
    if (!f.is_open()) {
        std::cout << "  (no peers.json at " << kPeersJsonPath << ")\n";
        return;
    }
    std::stringstream ss;
    ss << f.rdbuf();
    std::string body = ss.str();
    if (body.empty()) {
        std::cout << "  (peers.json empty)\n";
        return;
    }
    std::cout << "  --- peers.json ---\n";
    std::cout << body;
    if (!body.empty() && body.back() != '\n') std::cout << "\n";
    std::cout << "  ------------------\n";
}

}  // namespace

int main(int /*argc*/, char* /*argv*/[]) {
    std::ios::sync_with_stdio(false);
    std::cin.tie(nullptr);

    PrintBanner();

    while (true) {
        PrintMenu();
        std::string line;
        if (!std::getline(std::cin, line)) {
            std::cout << "\n(eof - exiting)\n";
            return 0;
        }
        line = Trim(line);
        if (line.empty()) continue;

        int choice = 0;
        try {
            choice = std::stoi(line);
        } catch (...) {
            std::cout << "(invalid choice)\n";
            continue;
        }

        switch (choice) {
            case 1: OptRefresh();      break;
            case 2: OptTestPayment();  break;
            case 3: OptHeyB();         break;
            case 4: OptPushTest();     break;
            case 5: OptListPeers();    break;
            case 6:
                std::cout << "Bye.\n";
                return 0;
            default:
                std::cout << "(unknown option)\n";
                break;
        }
    }
    return 0;
}
