const express = require("express");

const router = express.Router();
const {
    createTask,updateTask,deleteTask,toggleTask,getTasks
} = require("../controllers/taskController");

const authMiddleware = require("../middlewares/authMiddleware");

router.post("/", authMiddleware,createTask);

router.get("/", authMiddleware,getTasks);

router.delete("/:id",authMiddleware,deleteTask);

router.put("/:id", authMiddleware,updateTask);

router.patch("/:id/toggle", authMiddleware,toggleTask);

module.exports = router;