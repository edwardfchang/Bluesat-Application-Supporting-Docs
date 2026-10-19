clear; clc; close all;

%% =========================
%  Combined Mission Sensitivity Analysis
%  =========================

APPLY_CONSTRAINTS = true;

%% =========================
%  Constants
%  =========================

baseMass_kg      = 4.95;     % kg — base aircraft including battery
maxPayload_kg    = 2.0;      % kg — maximum payload mass
waterDensity     = 1.0;      % kg/L
Cartridge_mass   = 75;       % g per cartridge
Cartridge_mass_kg = Cartridge_mass / 1000;   % 0.075 kg

%% =========================
%  Shared Constants / Comp Rules
%  =========================

maxBatteryWh     = 100;      % maximum battery capacity
maxLaps          = 5;        % maximum laps

% Shared Metrics
batteryWh0       = 97.7;
laps0            = 4; 

%% =========================
%  Mission 2 Constants
%  =========================

Ic1 = 8;         % fixed score per cartridge
Ic2 = 3;         % extra score per cartridge per lap
Ce  = 8;         % base operating cost per lap
Cc  = 0.75;      % cartridge operating cost per lap

maxNetIncome     = 190;     % estimated best team net income
maxCartridge     = 27;      % realistic maximum cartridges

%% =========================
%  Mission 3 Constants
%  =========================

Aref             = 0.005;    % reference area for 80mm diameter bottle
maxWs_ft         = 5;        % maximum wingspan (ft)
maxDiam          = 0.095;    % maximum bottle diameter (m)
maxWaterVol      = 2;        % maximum water volume (L)
Pmax             = 100;      % maximum landing-zone points
maxNetScore      = 4;      % estimated best team net score (M3)

%% =========================
%  Mission 2 Baseline Aircraft
%  =========================

cartridge0       = 10;

%% =========================
%  Mission 3 Baseline Aircraft
%  =========================

Vw0              = 1.5;      % L
wingspan_ft0     = 4.92;     % ft
D0               = 0.08;     % m
Pland0           = 80;       % landing score

%% =========================
%  Ground Mission Baseline Aircraft
%  =========================

LoadTime0        = 50;      % seconds
minLoadTime      = 50;       

%% =========================
%  Mission 2 Equation
%  =========================

netIncome = @(C, L, B) ...
    C .* (Ic1 + Ic2 .* L) - ...
    L .* (Ce + C .* Cc) .* (B ./ 100);

m2Score = @(C, L, B) 1 + netIncome(C, L, B) ./ maxNetIncome;

%% =========================
%  Mission 3 Equation
%  =========================

netScore = @(P, V, L, W, B, D) ...
    (L .* V .* P ./ Pmax) ./ ...
    ((0.75 + 0.05 .* W + 0.15 .* B ./ 100) .* ...
    (1 + 0.25 .* (pi .* (D/2).^2 ./ Aref)));

m3Score = @(P, V, L, W, B, D) 2 + ...
    netScore(P, V, L, W, B, D) ./ maxNetScore;

%% =========================
%  Ground Mission Equation
%  =========================

% GMScore
GMScore = @(LT) minLoadTime ./ LT;

%% =========================
%  Total Score Function
%  =========================

% Single shared function: L and B are shared between M2 and M3
TotalScoreFunction = @(C, L, B, P, V, W, D, LT) ...
    1 + m2Score(C, L, B) + m3Score(P, V, L, W, B, D) + GMScore(LT);

%% =========================
%  Baseline Scores
%  =========================

baseScoreM2 = m2Score(cartridge0, laps0, batteryWh0);
baseScoreM3 = m3Score(Pland0, Vw0, laps0, wingspan_ft0, batteryWh0, D0);
baseScoreGM = GMScore(LoadTime0);
TotalScore  = TotalScoreFunction(cartridge0, laps0, batteryWh0, ...
                  Pland0, Vw0, wingspan_ft0, D0, LoadTime0);

fprintf("============= Mission 2 Baseline =============\n");
fprintf("Cartridges:   %.0f\n",    cartridge0);
fprintf("Laps:         %.0f\n",    laps0);
fprintf("Battery:      %.0f Wh\n", batteryWh0);
fprintf("M2 Score:     %.3f\n\n",  baseScoreM2);

fprintf("============= Mission 3 Baseline =============\n");
fprintf("Pland Score:  %.0f\n",    Pland0);
fprintf("Water Volume: %.1f L\n",  Vw0);
fprintf("Laps:         %.0f\n",    laps0);
fprintf("Wingspan:     %.2f ft\n", wingspan_ft0);
fprintf("Diameter:     %.4f m\n",  D0);
fprintf("M3 Score:     %.3f\n\n",  baseScoreM3);

fprintf("============= Ground Mission Baseline =============\n");
fprintf("Team Conversion Time: %.1f seconds\n", LoadTime0);
fprintf("GM Score:     %.3f\n\n",  baseScoreGM);

fprintf("<<Total Score: %.3f>>\n\n", TotalScore);

%% =========================
%  Sensitivity Analysis — Shared Scale
%  =========================

percentChange = -50:5:50;
scale = 1 + percentChange/100;

%% Mission 2 Sensitivity — vary one, hold all others at baseline
scoreCartridge = TotalScoreFunction(cartridge0 .* scale, laps0,          batteryWh0, ...
                     Pland0, Vw0, wingspan_ft0, D0, LoadTime0);
scoreLapsM2    = TotalScoreFunction(cartridge0,           laps0 .* scale, batteryWh0, ...
                     Pland0, Vw0, wingspan_ft0, D0, LoadTime0);
scoreBatteryM2 = TotalScoreFunction(cartridge0,           laps0,          batteryWh0 .* scale, ...
                     Pland0, Vw0, wingspan_ft0, D0, LoadTime0);

%% Mission 3 Sensitivity
scorePland     = TotalScoreFunction(cartridge0, laps0, batteryWh0, ...
                     Pland0 .* scale, Vw0,          wingspan_ft0,          D0,          LoadTime0);
scoreWatVol    = TotalScoreFunction(cartridge0, laps0, batteryWh0, ...
                     Pland0,          Vw0 .* scale, wingspan_ft0,          D0,          LoadTime0);
scoreLapsM3    = TotalScoreFunction(cartridge0, laps0 .* scale, batteryWh0, ...
                     Pland0,          Vw0,          wingspan_ft0,          D0,          LoadTime0);
scoreWs_ft     = TotalScoreFunction(cartridge0, laps0, batteryWh0, ...
                     Pland0,          Vw0,          wingspan_ft0 .* scale, D0,          LoadTime0);
scoreBatteryM3 = TotalScoreFunction(cartridge0, laps0, batteryWh0 .* scale, ...
                     Pland0,          Vw0,          wingspan_ft0,          D0,          LoadTime0);
scoreDiamBot   = TotalScoreFunction(cartridge0, laps0, batteryWh0, ...
                     Pland0,          Vw0,          wingspan_ft0,          D0 .* scale, LoadTime0);

%% Ground Mission Sensitivity
scoreGroundMission = TotalScoreFunction(cartridge0, laps0, batteryWh0, ...
                         Pland0, Vw0, wingspan_ft0, D0, LoadTime0 .* scale);

%% =========================
%  Optional Constraints
%  =========================

if APPLY_CONSTRAINTS

    % ── Mission 2 constraints ──────────────────────────────
    invalidCartridge = (cartridge0  .* scale) > maxCartridge;
    invalidLapsM2    = (laps0       .* scale) > maxLaps;
    invalidBatteryM2 = (batteryWh0  .* scale) > maxBatteryWh;

    scoreCartridge(invalidCartridge) = NaN;
    scoreLapsM2(invalidLapsM2)       = NaN;
    scoreBatteryM2(invalidBatteryM2) = NaN;

    % ── Mission 3 constraints ──────────────────────────────
    invalidPland    = (Pland0       .* scale) > Pmax;
    invalidWaterVol = (Vw0          .* scale) > maxWaterVol;
    invalidLapsM3   = (laps0        .* scale) > maxLaps;
    invalidWingSpan = (wingspan_ft0  .* scale) > maxWs_ft;
    invalidBatteryM3= (batteryWh0   .* scale) > maxBatteryWh;
    invalidDiam     = (D0           .* scale) > maxDiam;

    scorePland(invalidPland)         = NaN;
    scoreWatVol(invalidWaterVol)     = NaN;
    scoreLapsM3(invalidLapsM3)       = NaN;
    scoreWs_ft(invalidWingSpan)      = NaN;
    scoreBatteryM3(invalidBatteryM3) = NaN;
    scoreDiamBot(invalidDiam)        = NaN;

    % ── Ground mission constraints ─────────────────────────
    invalidGroundMission = (LoadTime0 .* scale) < minLoadTime;
    scoreGroundMission(invalidGroundMission) = NaN;

end

%% =========================
%  Convert to Percentage Change — all vs TotalScore baseline
%  =========================

changeCartridge    = 100 * (scoreCartridge     - TotalScore) ./ TotalScore;
changeLapsM2       = 100 * (scoreLapsM2        - TotalScore) ./ TotalScore;
changeBatteryM2    = 100 * (scoreBatteryM2     - TotalScore) ./ TotalScore;

changePland        = 100 * (scorePland         - TotalScore) ./ TotalScore;
changeWatVol       = 100 * (scoreWatVol        - TotalScore) ./ TotalScore;
changeLapsM3       = 100 * (scoreLapsM3        - TotalScore) ./ TotalScore;
changeWs_ft        = 100 * (scoreWs_ft         - TotalScore) ./ TotalScore;
changeBatteryM3    = 100 * (scoreBatteryM3     - TotalScore) ./ TotalScore;
changeDiamBot      = 100 * (scoreDiamBot       - TotalScore) ./ TotalScore;
changeGroundMission= 100 * (scoreGroundMission - TotalScore) ./ TotalScore;

%% =========================
%  Plot — Combined Total Score Sensitivity
%  =========================

figure;
hold on;

% Mission 2 variables
plot(percentChange, changeCartridge, "-o", "LineWidth", 2, "DisplayName", "Cartridge Count");
plot(percentChange, changeLapsM2, "-o", "LineWidth", 2, "DisplayName", "Laps");
plot(percentChange, changeBatteryM2, "-o", "LineWidth", 2, "DisplayName", "Battery Capacity");

% Mission 3 variables
plot(percentChange, changePland, "-o", "LineWidth", 2, "DisplayName", "Pland Score");
plot(percentChange, changeWatVol, "-o", "LineWidth", 2, "DisplayName", "Water Volume");
plot(percentChange, changeWs_ft, "-o", "LineWidth", 2, "DisplayName", "Wingspan");
plot(percentChange, changeBatteryM3, "-o", "LineWidth", 2, "DisplayName", "Battery Capacity (M3)");
plot(percentChange, changeDiamBot, "-o", "LineWidth", 2, "DisplayName", "Bottle Diameter");

% Ground mission
plot(percentChange, changeGroundMission, "--", "LineWidth", 2, "DisplayName", "Load Time");

xlabel("Change in Input Variable (%)");
ylabel("Change in Total Score (%)");
title("Combined Total Mission Score Sensitivity Analysis");
legend("Location", "best");
grid on;
box on;

%% =========================
%  Tornado Plot — Combined Total Score Sensitivity
%  =========================

idxLow  = find(percentChange == -10);
idxHigh = find(percentChange == +10);

% Merge shared variables by averaging M2 and M3 contributions
% deltaHigh_Laps    = (changeLapsM2(idxHigh)    + changeLapsM3(idxHigh))    / 2;
% deltaLow_Laps     = (changeLapsM2(idxLow)     + changeLapsM3(idxLow))     / 2;
% deltaHigh_Battery = (changeBatteryM2(idxHigh) + changeBatteryM3(idxHigh)) / 2;
% deltaLow_Battery  = (changeBatteryM2(idxLow)  + changeBatteryM3(idxLow))  / 2;

% ADDED AFTER: What should've actually been done
deltaHigh_Laps    = (changeLapsM2(idxHigh)    + changeLapsM3(idxHigh));
deltaLow_Laps     = (changeLapsM2(idxLow)     + changeLapsM3(idxLow));
deltaHigh_Battery = (changeBatteryM2(idxHigh) + changeBatteryM3(idxHigh));
deltaLow_Battery  = (changeBatteryM2(idxLow)  + changeBatteryM3(idxLow));


varNames = {
    'Cartridge Count (M2)';
    'Laps';
    'Battery Capacity';
    'Pland Score (M3)';
    'Water Volume (M3)';
    'Wingspan (M3)';
    'Bottle Diameter (M3)';
    'Load Time (GM)'
};

deltaHigh = [
    changeCartridge(idxHigh);
    deltaHigh_Laps;
    deltaHigh_Battery;
    changePland(idxHigh);
    changeWatVol(idxHigh);
    changeWs_ft(idxHigh);
    changeDiamBot(idxHigh);
    changeGroundMission(idxHigh)
];

deltaLow = [
    changeCartridge(idxLow);
    deltaLow_Laps;
    deltaLow_Battery;
    changePland(idxLow);
    changeWatVol(idxLow);
    changeWs_ft(idxLow);
    changeDiamBot(idxLow);
    changeGroundMission(idxLow)
];

% This part of the code removes the effects of potential constraints
% on the tornado chart, also sorting from greatest to smallest change.
deltaHighClean = deltaHigh;
deltaLowClean  = deltaLow;
deltaHighClean(isnan(deltaHighClean)) = 0;
deltaLowClean(isnan(deltaLowClean))   = 0;

totalWidth = abs(deltaHighClean) + abs(deltaLowClean);
[~, sortIdx] = sort(totalWidth, 'ascend');

varNamesSorted  = varNames(sortIdx);
deltaHighSorted = deltaHigh(sortIdx);
deltaLowSorted  = deltaLow(sortIdx);


%% Plot
figure;
hold on;

yPos = 1:length(varNames);

for i = 1:length(varNames)
    barh(yPos(i), deltaHighSorted(i), 'FaceColor', [0.2 0.6 0.9]);
    barh(yPos(i), deltaLowSorted(i),  'FaceColor', [0.9 0.4 0.3]);
end

xline(0, 'k-', 'LineWidth', 1.5);

yticks(yPos);
yticklabels(varNamesSorted);

xlabel('Change in Total Score (%) at \pm10% Perturbation');
title('Tornado Plot — Combined Total Score Sensitivity');
legend('+10% perturbation', '-10% perturbation', 'Location', 'southeast');
grid on;
box on;
