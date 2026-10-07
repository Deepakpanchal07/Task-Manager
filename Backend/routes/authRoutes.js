const express= require("express");

const router= express.Router();
const { registerUser, loginUser,resetPassword,verifyResetOtp,forgotPassword  } = require("../controllers/authController");

router.post("/register", registerUser);
router.post("/login", loginUser);
router.post("/forgot-password",forgotPassword);
router.post("/verify-otp",verifyResetOtp);
router.post("/reset-password",resetPassword);

module.exports= router;