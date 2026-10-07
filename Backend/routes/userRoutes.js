const express = require("express");
const router = express.Router();

const protect = require("../middlewares/authMiddleware");

const {
  getUserProfile, updateProfile,changePassword
} = require("../controllers/userController");

router.get("/profile", protect, getUserProfile);
router.put("/profile",protect,updateProfile);
router.put("/change-password",protect,changePassword);

module.exports = router;