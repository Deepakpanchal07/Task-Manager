const User = require("../models/User");
const bcrypt = require("bcrypt");

const getUserProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user.id)
      .select("-password");

    if (!user) {
      return res.status(404).json({
        message: "User not found",
      });
    }

    return res.status(200).json({
      message: "Profile fetched successfully",
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        createdAt: user.createdAt,
      },
    });
  } catch (error) {
    return res.status(500).json({
      message: "Server error",
    });
  }
};


const updateProfile = async(req,res) =>{
  try{
    const {name, email} = req.body;

    const user = await User.findById(req.user.id);

    if(!user){
      return res.status(404).json({
        message: "User not found",

      });
    }

    if(name !== undefined){
      if(!name.trim()){
        return res.status(400).json({
          message: "Name cannot be empty",
        });
      }
      user.name = name.trim();

    }
    if(email !== undefined) {
      if(!email.trim()){
        return res.status(400).json({
          message: "Email cannot be empty"
        });
      }
      const newEmail = email.trim().toLowerCase();

      const existingUser = await User.findOne({
        email: newEmail,
        _id: {$ne: req.user.id},
      });
      if(existingUser){
        return res.status(400).json({
          message: "Email is already in use",
        });
      }
      user.email = newEmail;
    }

    await user.save();

    res.status(200).json({
      message: "Profile updated successfully",

      user: {
        id: user._id,
        name: user.name,
        email: user.email,
      },
    });


  }catch(error){
    console.error("update profile error",error);

    res.status(500).json({
      message: "failed to update profile",
    });

  }
};


const changePassword = async(req,res)=>{
  try{
    const{
      currentPassword,
      newPassword,
    } = req.body;

    if(!currentPassword || !newPassword) {
      return res.status(400).json({
        message: "Current password and new password are required",

      });
    }
    if(newPassword.length <6) {
      return res.status(400).json({
        message: "New password must be at least 6 characters",
      });
    }
    const user  = await User.findById(req.user.id);

    if(!user){
      return res.status(404).json({
        message: "User not found",
      });
    }

    const isPasswordCorrect = await bcrypt.compare(currentPassword,user.password);
    if(!isPasswordCorrect) {
      return res.status(400).json({
        message:" New password must be different from current password",
      });
    }

    const hashedPassword = await bcrypt.hash(newPassword,10);

    user.password  = hashedPassword;

    await user.save();

    res.status(200).json({
      message:"Password change successfully"
    });
  }catch(error){
    console.error("change password error: ",
      error,
    );
    res.status(500).json({
      message: "Failed to change password",
    });

  }
};

module.exports = { getUserProfile, updateProfile, changePassword};