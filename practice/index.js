const http= require("http");

const server= http.createServer((req, res)=>{
    

    if(req.url=="/" && req.method=="GET"){
        res.end(" Welcome to Home Page")
    }
    else if(req.url=="/login"){
        res.end("welcome to login page")
    }
    else if(req.url=="/register"){
        res.end("welcome to register Page");
    }
    else{
        res.end("page not found");
    }
});

server.listen(3000, ()=>{
    console.log("server running on port 3000");
})