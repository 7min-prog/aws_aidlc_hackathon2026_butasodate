"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.addPoints = addPoints;
exports.deductPoints = deductPoints;
const avatar_points_service_1 = require("../services/avatar-points-service");
async function addPoints(userId, points, categoryType, subCategoryId) {
    const result = await (0, avatar_points_service_1.addPoints)(userId, points, categoryType, subCategoryId);
    return { totalPoints: result.totalPoints, level: result.level };
}
async function deductPoints(userId, points, categoryId) {
    const result = await (0, avatar_points_service_1.deductPoints)(userId, points, 'FOOD', categoryId);
    return { avatarStatus: { totalPoints: result.totalPoints, level: result.level }, devolutionOccurred: result.devolved };
}
//# sourceMappingURL=avatar-connector.js.map