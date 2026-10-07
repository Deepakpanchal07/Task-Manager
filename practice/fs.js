const fs= require("fs");

fs.writeFileSync("hello.txt", "hello from node.js");

console.log("File Created");

// const data= fs.readFile("hello.txt", 'utf8', (err, data)=>{
//     if(err){
//         console.log("Error reading file", err);
//         return;
//     }
//     console.log(data);
// });

const data= fs.readFileSync("hello.txt",'utf8');
console.log(data);