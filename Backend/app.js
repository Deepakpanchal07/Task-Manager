
const express = require("express");
const cors= require("cors");

const authRoutes = require("./routes/authRoutes");
const userRoutes= require("./routes/userRoutes");
const taskRoutes = require("./routes/taskRoutes")
const errorMiddleware = require("./middlewares/errorMiddleware");


const app = express();

// Middleware to parse incoming JSON
app.use(express.json());
app.use(cors());


// Home route
app.get("/", (req, res) => {
  res.status(200).json({
    success: true,
    message: "Registration API is running",
  });
});

// Authentication routes
app.use("/auth", authRoutes);
app.use("/users", userRoutes);
app.use("/tasks",taskRoutes);
// Error handling middleware (must be after routes)
app.use(errorMiddleware);

module.exports = app;