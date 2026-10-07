const express= require("express");
const app= express();
const {add, subtract, multiply,divide}= require("./math");
app.use(express.json());

console.log(add(3,2));
console.log(subtract(3,2));

app.get("/", (req, res)=>{
    res.send("Hello from home pAGE")
});

app.post("/", (req, res)=>{
    const {name, age, pass, city}= req.body;

    res.send(`${name}, ${age},${pass}`);
})

app.get("/login/:id", (req, res)=>{
    const query= req.query.page;
    const value= req.params.id;

    console.log(`${query},${value}`);
    res.status(200).json({
        message: "Hello ji",
        age: 22,
        bool: true
    });

});
app.get("/math", (req, res)=> {
    res.status(200).send(`product: ${multiply(4,5)}, Division: ${divide(10,2)}`);
});



app.use((req,res)=>{
    res.status(404).send("page not found");
})

app.listen(3000, ()=>{
    console.log("server running on 3000");
})