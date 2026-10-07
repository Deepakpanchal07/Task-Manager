const User= require("../models/User");
const bcrypt= require("bcryptjs");
const generateToken= require("../utils/generateToken");
const sendEmail = require("../utils/sendEmail");



const registerUser= async(req, res, next)=>{
    try{
        const {name, email, password} = req.body;

    if(!name || !email || !password){
        return res.status(400).json({
            success: false,
            message: "All fields are required"
        });
    }

    const normalizedName= name.trim();
    const normalizedEmail= email.trim().toLowerCase();

    if(normalizedName.length < 2){
        return res.status(401).json({
            success: false,
            message: "Name must contain at least 2 characters"
        });
    }

    if(!normalizedEmail.includes("@")){
        return res.status(401).json({
            success: false,
            message: "Please enter a valid email"
        });
    }

    if(password.length<  6){
        return res.status(401).json({
            success: false,
            message: "Password must have atleast 6 characters"
        });
    }

    const existingUser= await User.findOne({
        email: normalizedEmail
    });

    if(existingUser){
        return res.status(409).json({
            success: false,
            message: "Email is already registered",
        });
    }

    const hashedpassword= await bcrypt.hash(password, 10);

    const newUser= await User.create({
        name: normalizedName,
        email: normalizedEmail,
        password: hashedpassword
    });

    const token= generateToken(newUser._id);

    return res.status(201).json({
        success: true,
        token,
        message: "Registeration Successful",
        user: {
            id: newUser._id,
            name: newUser.name,
            email: newUser.email
        },
    })
    }
    catch(error){
       if(error.code === 11000){
         return res.status(409).json({
            success: false,
            message: "Email is already registered"
        });
       }

        next(error);
    }
   
}

const loginUser= async(req, res, next)=>{
    try{
        const {email, password}= req.body;

        if(!email || !password){
            return res.status(400).json({
                success: false,
                message: "Invalid email or password"
            });
        }

        const normalizedEmail= email.trim().toLowerCase();

        const user= await User.findOne({
            email: normalizedEmail
        });

        if(!user){
            return res.status(401).json({
                sucess: false,
                message: "Invalid email or password"
            })
        }

        const isPasswordCorrect= await bcrypt.compare(
            password,
            user.password
        );

        if(!isPasswordCorrect){
            return res.status(401).json({
                success: false,
                message: "Invalid email or password"
            });
        };
        const token= generateToken(user._id);

        console.log(token);

        return res.status(200).json({
            success: true,
            token,
            message: "Login Successful",
        });

    }catch(error){
        next(error);
    }
}

const forgotPassword = async (req,res)=>{
    try{
        const {email} = req.body;

        if(!email || !email.trim()) {
            return res.status(400).json({
                message: "Email is required"
            });
        }
        const normalizedEmail = email.trim().toLowerCase();

        const user = await User.findOne({
            email:normalizedEmail,
        });

        if(!user) {
            return res.status(200).json({
                message: "If an account exists with this email, a reset otp has been sent",
            });
        }
        const otp = Math.floor(100000+ Math.random()*900000).toString();
        const otpHash = await bcrypt.hash(otp,10);
        const otpExpires = new Date(Date.now()+10*60*1000);

        user.resetOtpHash = otpHash;
        user.resetOtpExpires = otpExpires;
        user.resetVerified = false;

        await user.save();
        await sendEmail({
            to: user.email,
            subject: "Password Reset OTP",
            text: `Your Password reset OTP is ${otp}. It is valid for 10 minutes.`,
            html:`
             <div style="font-family: Arial , sans-serif;">
                <h2>Password Reset</h2>
                <p>HEllo ${user.name}</p>
                <p>We Received a request to reset your password.</p>
                <p>Your OTP is: </p>
                <h1>${otp}</h1>
                <p>If you did not request this , you can ignore this email.</p>
            </div>`
        });
        return res.status(200).json({
            message: "if an account exists with this email, a reset OTP has been sent.",
        });

    }catch(error){
        console.error(
            "Forgot Password error: ",
            error
        );
        return res.status(500).json({
            message: "Failed to process forgot password request",
        });
    }
}

const verifyResetOtp = async (req,res) =>{
    try{
        const {email,otp} = req.body;
        if(!email || !otp) {
            return res.status(400).json({
                message: "Email and OTP are required",               
            });
        }
        const user = await User.findOne({
            email : email.trim().toLowerCase(),
        });

        if(!user) {
            return res.status(400).json({
                message: "Invalid OTP",
            });
        }
        if(!user.resetOtpHash || !user.resetOtpExpires){
            return res.status(400).json({
                message:"OTP is invalid or expired",
            });
        }

        if(
            new Date()>user.resetOtpExpires
        ){
            user.resetOtpExpires =null;
            user.resetOtpHash = null;
            user.resetVerifeid = false;

            await user.save();

            return res.status(400).json({
                message: "OTP has expired",
            });
        }

        const isOtpCorrect = await bcrypt.compare(otp.toString(),user.resetOtpHash);
        if(!isOtpCorrect){
            return res.status(400).json({
                messaeg: "Invalid OTP",
            });
        }
        user.resetVerified = true;

        await user.save();

        return res.status(200).json({
            messaeg: "OTP Verified successfully",
        });
    }catch(error){
        console.error("Verify OTP error:");
        return res.status(500).json({
            message: "Failed to Verify OTP",
        });
    }

}


const resetPassword = async (req,res)=>{
    try{
        const{
            email,
            newPassword,
        }= req.body
        if(!email || !newPassword) {
            return res.status(400).json({
                message: "Email and New password are required",
            });
        }
        if(newPassword.length<6){
            return res.status(400).json({
                message:"Password must be at least 6 characters",
            });
        }
        const user = await User.findOne({
            email: email.trim().toLowerCase(),
        });

        if(!user){
            return res.status(400).json({
                message:"Invalid Password reset request",
            });
        }
        if(!user.resetVerified) {
            return res.status(400).json({
                message:"Please Verify the otp first",
            });
        }
        const hashedPassword = await bcrypt.hash(newPassword,10);
        user.password = hashedPassword;

        user.resetOtpHash = null;
        user.resetOtpExpires = null;
        user.resetVerified = false;

        await user.save();

        return res.status(200).json({
            message: "Password reset successfully",
        });
    }catch(error){
        console.error("Reset Password error:",error);

        return res.status(500).json({
            message:"Failed to reset password",
        });
    }
}

module.exports= {registerUser, loginUser,resetPassword,forgotPassword,verifyResetOtp};