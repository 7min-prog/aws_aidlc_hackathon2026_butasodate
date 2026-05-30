"use strict";
// === Enums ===
Object.defineProperty(exports, "__esModule", { value: true });
exports.HealthEvaluation = exports.HealthCategory = exports.CategoryType = exports.RecordSource = void 0;
var RecordSource;
(function (RecordSource) {
    RecordSource["MANUAL"] = "MANUAL";
    RecordSource["AUTO_DETECTED"] = "AUTO_DETECTED";
})(RecordSource || (exports.RecordSource = RecordSource = {}));
var CategoryType;
(function (CategoryType) {
    CategoryType["FOOD"] = "FOOD";
    CategoryType["LIFESTYLE"] = "LIFESTYLE";
})(CategoryType || (exports.CategoryType = CategoryType = {}));
var HealthCategory;
(function (HealthCategory) {
    HealthCategory["WEIGHT"] = "WEIGHT";
    HealthCategory["STEPS"] = "STEPS";
    HealthCategory["SLEEP"] = "SLEEP";
})(HealthCategory || (exports.HealthCategory = HealthCategory = {}));
var HealthEvaluation;
(function (HealthEvaluation) {
    HealthEvaluation["UNHEALTHY"] = "UNHEALTHY";
    HealthEvaluation["HEALTHY"] = "HEALTHY";
    HealthEvaluation["NEUTRAL"] = "NEUTRAL";
})(HealthEvaluation || (exports.HealthEvaluation = HealthEvaluation = {}));
//# sourceMappingURL=types.js.map