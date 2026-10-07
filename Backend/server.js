
const app = require("./app");
const connectDB= require("./config/db");
const taskRoutes= require("./routes/taskRoutes")
require("dotenv").config();
const PORT = process.env.PORT;

const startServer= async()=>{
  await connectDB();

  app.listen(PORT, ()=>{
    console.log(`Server running on port ${PORT}`);
  })
};
startServer();