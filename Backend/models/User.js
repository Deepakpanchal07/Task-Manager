const mongoose= require("mongoose");

const userSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true,
        trim: true,
        minlength: 2
    },
    email: {
        type: String,
        required: true,
        unique: true,
        lowercase: true,
        trim: true
    },
    password: {
        type: String,
        required: true,
        minlength: 6
    },
    resetOtpHash:{
        type: String,
        default: null,
    },
    resetOtpExpires: {
        type: Date,
        default: null,
    },
    resetVerified:{
        type: Boolean,
        default: false,
    },
    
},{
    timestamps: true
});

const User= mongoose.model("User", userSchema);

module.exports= User;