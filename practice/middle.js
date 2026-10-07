const express = require("express");

const app = express();

app.use(express.json());

const logger = (req, res, next) => {
    if(req.body.age>0){
        next();
    }
    else{
        res.status(404).send("you are not eligible")
    }

    // if(req.url=="/"){
    //     next();
    // }
    // else{
    //     res.status(400).send("Galat page hai");
    // }
    
};

// app.use(logger);

// app.get("/", logger, (req, res) => {
//     console.log("home page")
//     res.send("Home");
// });

app.post("/",logger, (req, res) => {
    console.log("home page")
    res.send("Home");
});


app.get("/users", (req, res) => {
    console.log("users page");
    res.send("Users");
});

app.get("/products", (req, res) => {
    console.log("products page")
    res.send("Products");
});

app.listen(3000, ()=>{
    console.log("server running on 3000")
});