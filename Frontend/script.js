document.addEventListener("DOMContentLoaded", function() {
    const taskInput = document.getElementById("taskInput");
    const addTaskBtn = document.getElementById("addTaskBtn");
    const taskList = document.getElementById("taskList");

    addTaskBtn.addEventListener("click", function() {
        const taskText = taskInput.value.trim();
        if (taskText !== "") {
            addTask(taskText);
            taskInput.value = "";
        }
    });

    taskList.addEventListener("click", function(event) {
        if (event.target.classList.contains("deleteBtn")) {
            event.target.parentNode.remove();
        }
    });

    function addTask(taskText) {
        const li = document.createElement("li");
        li.innerHTML = `
            ${taskText}
            <button class="deleteBtn">Delete</button>
        `;
        taskList.appendChild(li);
    }
});

