const express= require("express");
const cors= require("cors")
const app= express();
app.use(cors())
app.use(express.json());

app.get("/", (req, res)=>{
    res.send("Registeration backend is running");
});

const logger = (req,res,next)=>{
    if(req.body.name.length>6 && req.body.email.length>6 && req.body.password.length>6){
        next();
    }else
        res.status(400).json({
            message: "must have at least 6 characters"
        })
}
app.post("/register",logger, (req, res)=>{
    const {name, email , password}= req.body;

    if(!name || !email || !password){
        return res.status(400).json({
            success: false,
            message: "Please provide all fields"
        });
    }
    if(!email.includes("@")){
        return res.status(400).json({
            success: false,
            message: "Please enter a valid email"
        });
    }
    

    res.status(200).json({
        success: true,
        message: "Registration successful",
        user: {
            name,
            email
        }
    });
});

const PORT= 5000;

app.listen(PORT, ()=>{
    console.log(`Server running on port ${PORT}`);
});