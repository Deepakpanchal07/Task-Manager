const Task = require("../models/Task");

const createTask = async (req ,res)=>{
    try{
        const{title , description} = req.body;

        if(!title || !title.trim()){
        return res.status(400).json({
            message: "Task title  is required"
        });
    }
    const task = await Task.create({
        title: title.trim(),
        description: description || " ",
        user: req.user.id,

    });
    res.status(200).json({
        message: "Task Created successfully",
        task,
        });
    }
    
    catch(error) {
        res.status(500).json({
            message: "Failed to create User",

        });
    }

}

const getTasks = async (req,res)=>{
    try{
        const search = req.query.search || "";
        const status = req.query.status || "all";
        
        const page = Number(req.query.page) || 1;
        const limit = Number(req.query.limit) ||5;

        const skip = (page-1)*limit;

        const query = {
            user: req.user.id
        }; 
        if(search.trim()){
            query.$or = [
                {
                    title: {
                        $regex: search.trim(),
                        $options: "i",
                    }
                },
                {
                    description: {
                        
                        $regex:  search.trim(),
                        $options: "i",
                    
                    }
                }
            ];
        }

        if(status === "completed"){
            query.completed = true;
        }

        if(status === "pending"){
            query.completed = false;
        }

        const totalTasks = await Task.countDocuments(query);


        const task = await Task.find(query).sort({
            createdAt: -1
        }).skip(skip).limit(limit);

        const totalPages = Math.ceil(totalTasks/limit);

        res.status(200).json({
            message: "Task fetch successfully",
            tasks: task,

            pagination:{
                currentPage: page,
                limit,
                totalTasks,
                totalPages,
                hasNextPage: page<totalPages,
                hasPreviousPage: page>1,
            }
        });
    }catch(error){
        res.status(500).json({
            message: "failed to fetch task",

        });
    }
};

const updateTask = async (req ,res) =>{
    try{
        const {title, description} = req.body;

        const task = await Task.findOne({
            _id: req.params.id,
            user: req.user.id,
        });
        if(!task){
            return res.status(404).json({
                message: "task not found",
            });
        }
        if(title !== undefined ){
            if(!title.trim()){
            return res.status(400).json({
                message: "task title cannot be empty"
            });
        }
        task.title = title.trim();
    }
 
    if(description !== undefined){
        task.description = description;
    }
    await task.save();

    res.status(200).json({
        message: "task updated successfully",
        task,
    })

    }catch(error){
        res.status(500).json({
            message: "Failed to Update Tasks",
        })
    }
};


const deleteTask = async(req,res)=>{
    try{
        const task = await Task.findOneAndDelete({
            _id: req.params.id,
            user: req.user.id,
        });
        if(!task){
            return res.status(404).json({
                message: "Task not found"
            });

        }
        res.status(200).json({
            mesaage: "Delete task successfully",
        })
      }catch(error){
        res.status(500).json({
            message: "failed to delete task"
        })
    }
};


const toggleTask = async(req, res) =>{
    try{
        const task = await Task.findOne({
            _id: req.params.id,
            user: req.user.id,
        })
        if(!task){
            return res.status(404).json({
                message: "Task not found"
            });
        }
        task.completed = !task.completed;

        await task.save();
        res.status(200).json({
            message:"Task updated successfully",
            task,
        })
    
    }catch(error){
        res.status(500).json({
            message:"Failed to update task"
        })
    }
}

module.exports = {createTask,updateTask,deleteTask,toggleTask,getTasks}

