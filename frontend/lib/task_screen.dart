import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final FlutterSecureStorage storage =
      const FlutterSecureStorage();

  final String baseUrl = "http://localhost:5000";

  // Search
  final TextEditingController searchController =
      TextEditingController();

  // Tasks
  List<dynamic> tasks = [];

  // Loading
  bool isLoading = true;

  // Search UI
  bool isSearching = false;

  // Filter
  String selectedFilter = "all";

  // Pagination
  int currentPage = 1;
  int totalPages = 1;
  int limit = 5;

  bool hasNextPage = false;
  bool hasPreviousPage = false;

  @override
  void initState() {
    super.initState();

    fetchTasks();
  }

  // --------------------------------------------------
  // GET HEADERS
  // --------------------------------------------------

  Future<Map<String, String>> getHeaders() async {
    final token = await storage.read(key: "token");

    if (token == null || token.isEmpty) {
      throw Exception("Please login again");
    }

    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  // --------------------------------------------------
  // FETCH TASKS
  // --------------------------------------------------

  Future<void> fetchTasks({
    int page = 1,
  }) async {
    setState(() {
      isLoading = true;
    });

    try {
      final headers = await getHeaders();

      final search = searchController.text.trim();

      final uri = Uri.parse(
        "$baseUrl/tasks"
        "?page=$page"
        "&limit=$limit"
        "&status=$selectedFilter"
        "&search=${Uri.encodeComponent(search)}",
      );

      print("GET URL: $uri");

      final response = await http.get(
        uri,
        headers: headers,
      );

      print("Status: ${response.statusCode}");
      print("Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          tasks = data["tasks"] ?? [];

          final pagination =
              data["pagination"] ?? {};

          currentPage =
              pagination["currentPage"] ?? 1;

          totalPages =
              pagination["totalPages"] ?? 1;

          hasNextPage =
              pagination["hasNextPage"] ?? false;

          hasPreviousPage =
              pagination["hasPreviousPage"] ?? false;
        });
      } else if (response.statusCode == 401) {
        showMessage(
          "Session expired. Please login again.",
        );
      } else {
        showMessage(
          "Failed to fetch tasks",
        );
      }
    } catch (error) {
      showMessage("Error: $error");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // --------------------------------------------------
  // CREATE TASK
  // --------------------------------------------------

  Future<void> createTask(
    String title,
    String description,
  ) async {
    try {
      final headers = await getHeaders();

      final response = await http.post(
        Uri.parse("$baseUrl/tasks"),
        headers: headers,
        body: jsonEncode({
          "title": title,
          "description": description,
        }),
      );

      if (response.statusCode == 200) {
        await fetchTasks(page: 1);
        if (!mounted) return;

        // Navigator.pop(context);

        showMessage(
          "Task created successfully",
        );

        // Go back to page 1
        // await fetchTasks(page: 1);
      } else {
        final data = jsonDecode(response.body);

        showMessage(
          data["message"] ??
              "Failed to create task",
        );
      }
    } catch (error) {
      showMessage("Error: $error");
    }
  }

  // --------------------------------------------------
  // UPDATE TASK
  // --------------------------------------------------

  Future<void> updateTask(
    String id,
    String title,
    String description,
  ) async {
    try {
      final headers = await getHeaders();

      final response = await http.put(
        Uri.parse("$baseUrl/tasks/$id"),
        headers: headers,
        body: jsonEncode({
          "title": title,
          "description": description,
        }),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;

        Navigator.pop(context);

        showMessage(
          "Task updated successfully",
        );

        await fetchTasks(
          page: currentPage,
        );
      } else {
        final data = jsonDecode(response.body);

        showMessage(
          data["message"] ??
              "Failed to update task",
        );
      }
    } catch (error) {
      showMessage("Error: $error");
    }
  }

  // --------------------------------------------------
  // TOGGLE TASK
  // --------------------------------------------------

  Future<void> toggleTask(String id) async {
    try {
      final headers = await getHeaders();

      final response = await http.patch(
        Uri.parse("$baseUrl/tasks/$id/toggle"),
        headers: headers,
      );

      if (response.statusCode == 200) {
        await fetchTasks(
          page: currentPage,
        );
      } else {
        showMessage(
          "Failed to update task status",
        );
      }
    } catch (error) {
      showMessage("Error: $error");
    }
  }

  // --------------------------------------------------
  // DELETE TASK
  // --------------------------------------------------

  Future<void> deleteTask(String id) async {
    try {
      final headers = await getHeaders();

      final response = await http.delete(
        Uri.parse("$baseUrl/tasks/$id"),
        headers: headers,
      );

      if (response.statusCode == 200) {
        showMessage(
          "Task deleted successfully",
        );

        // Refresh current page
        await fetchTasks(
          page: currentPage,
        );
      } else {
        showMessage(
          "Failed to delete task",
        );
      }
    } catch (error) {
      showMessage("Error: $error");
    }
  }

  // --------------------------------------------------
  // FILTER
  // --------------------------------------------------

  void changeFilter(String filter) {
    setState(() {
      selectedFilter = filter;
    });

    // Whenever filter changes,
    // start from page 1.
    fetchTasks(page: 1);
  }

  // --------------------------------------------------
  // SEARCH
  // --------------------------------------------------

  void performSearch() {
    // Search should start from page 1
    fetchTasks(page: 1);
  }

  // --------------------------------------------------
  // NEXT PAGE
  // --------------------------------------------------

  void nextPage() {
    if (hasNextPage) {
      fetchTasks(
        page: currentPage + 1,
      );
    }
  }

  // --------------------------------------------------
  // PREVIOUS PAGE
  // --------------------------------------------------

  void previousPage() {
    if (hasPreviousPage) {
      fetchTasks(
        page: currentPage - 1,
      );
    }
  }

  // --------------------------------------------------
  // MESSAGE
  // --------------------------------------------------

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // --------------------------------------------------
  // ADD / EDIT TASK
  // --------------------------------------------------

  void showTaskDialog({
    Map<String, dynamic>? task,
  }) {
    final titleController =
        TextEditingController(
      text: task?["title"] ?? "",
    );

    final descriptionController =
        TextEditingController(
      text: task?["description"] ?? "",
    );

    final bool isEditing = task != null;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            isEditing
                ? "Edit Task"
                : "Add Task",
          ),

          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller:
                      titleController,
                  decoration:
                      const InputDecoration(
                    labelText: "Task Title",
                    border:
                        OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller:
                      descriptionController,
                  maxLines: 3,
                  decoration:
                      const InputDecoration(
                    labelText:
                        "Description",
                    border:
                        OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child:
                  const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: () async {
                final title =
                    titleController.text
                        .trim();

                final description =
                    descriptionController
                        .text
                        .trim();

                if (title.isEmpty) {
                  showMessage(
                    "Please enter a task title",
                  );
                  return;
                }

                if (isEditing) {
                  await updateTask(
                    task["_id"].toString(),
                    title,
                    description,
                  );
                } else {
                  await createTask(
                    title,
                    description,
                  );
                  if(dialogContext.mounted){
                    Navigator.pop(dialogContext);
                  }
                }
              },
              child: Text(
                isEditing
                    ? "Update"
                    : "Create",
              ),
            ),
          ],
        );
      },
    );
  }

  // --------------------------------------------------
  // DELETE CONFIRMATION
  // --------------------------------------------------

  void confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title:
              const Text("Delete Task"),

          content: const Text(
            "Are you sure you want to delete this task?",
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child:
                  const Text("Cancel"),
            ),

            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.red,
                foregroundColor:
                    Colors.white,
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );

                deleteTask(id);
              },
              child:
                  const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  // --------------------------------------------------
  // BUILD UI
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isSearching
            ? TextField(
                controller:
                    searchController,
                autofocus: true,
                decoration:
                    const InputDecoration(
                  hintText:
                      "Search tasks...",
                  border:
                      InputBorder.none,
                ),
                onSubmitted: (value) {
                  performSearch();
                },
              )
            : const Text("My Tasks"),

        actions: [
          // Search button
          IconButton(
            icon: Icon(
              isSearching
                  ? Icons.close
                  : Icons.search,
            ),
            onPressed: () {
              if (isSearching) {
                searchController.clear();

                setState(() {
                  isSearching =
                      false;
                });

                fetchTasks(page: 1);
              } else {
                setState(() {
                  isSearching =
                      true;
                });
              }
            },
          ),

          // Refresh
          IconButton(
            icon:
                const Icon(Icons.refresh),
            onPressed: () {
              fetchTasks(
                page: currentPage,
              );
            },
          ),
        ],
      ),

      body: Column(
        children: [
          // -----------------------------------------
          // FILTER
          // -----------------------------------------

          Padding(
            padding:
                const EdgeInsets.all(12),

            child: Row(
              children: [
                Expanded(
                  child: FilterChip(
                    label:
                        const Text("All"),
                    selected:
                        selectedFilter ==
                            "all",
                    onSelected: (_) {
                      changeFilter(
                        "all",
                      );
                    },
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: FilterChip(
                    label:
                        const Text(
                      "Pending",
                    ),
                    selected:
                        selectedFilter ==
                            "pending",
                    onSelected: (_) {
                      changeFilter(
                        "pending",
                      );
                    },
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: FilterChip(
                    label:
                        const Text(
                      "Completed",
                    ),
                    selected:
                        selectedFilter ==
                            "completed",
                    onSelected: (_) {
                      changeFilter(
                        "completed",
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // -----------------------------------------
          // TASK LIST
          // -----------------------------------------

          Expanded(
            child: isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(),
                  )
                : tasks.isEmpty
                    ? const Center(
                        child: Text(
                          "No tasks found",
                          style:
                              TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () =>
                            fetchTasks(
                          page:
                              currentPage,
                        ),

                        child:
                            ListView.builder(
                          padding:
                              const EdgeInsets
                                  .all(12),

                          itemCount:
                              tasks.length,

                          itemBuilder:
                              (context,
                                  index) {
                            final task =
                                Map<String,
                                    dynamic>.from(
                              tasks[index],
                            );

                            final id =
                                task["_id"]
                                    .toString();

                            final title =
                                task["title"] ??
                                    "";

                            final description =
                                task["description"] ??
                                    "";

                            final completed =
                                task["completed"] ??
                                    false;

                            return Card(
                              margin:
                                  const EdgeInsets
                                      .only(
                                bottom: 12,
                              ),

                              child:
                                  ListTile(
                                leading:
                                    Checkbox(
                                  value:
                                      completed,

                                  onChanged:
                                      (_) {
                                    toggleTask(
                                      id,
                                    );
                                  },
                                ),

                                title:
                                    Text(
                                  title,

                                  style:
                                      TextStyle(
                                    decoration:
                                        completed
                                            ? TextDecoration
                                                .lineThrough
                                            : TextDecoration
                                                .none,
                                  ),
                                ),

                                subtitle:
                                    Text(
                                  description
                                          .toString()
                                          .isEmpty
                                      ? "No description"
                                      : description
                                          .toString(),
                                ),

                                trailing:
                                    PopupMenuButton<
                                        String>(
                                  onSelected:
                                      (value) {
                                    if (value ==
                                        "edit") {
                                      showTaskDialog(
                                        task:
                                            task,
                                      );
                                    }

                                    if (value ==
                                        "delete") {
                                      confirmDelete(
                                        id,
                                      );
                                    }
                                  },

                                  itemBuilder:
                                      (context) =>
                                          const [
                                    PopupMenuItem(
                                      value:
                                          "edit",
                                      child:
                                          Text(
                                        "Edit",
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value:
                                          "delete",
                                      child:
                                          Text(
                                        "Delete",
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),

          // -----------------------------------------
          // PAGINATION
          // -----------------------------------------

          if (!isLoading && tasks.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 16,
                vertical: 12,
              ),

              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .center,

                children: [
                  // Previous
                  IconButton(
                    onPressed:
                        hasPreviousPage
                            ? previousPage
                            : null,

                    icon: const Icon(
                      Icons
                          .chevron_left,
                    ),
                  ),

                  Text(
                    "Page $currentPage of $totalPages",
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  // Next
                  IconButton(
                    onPressed:
                        hasNextPage
                            ? nextPage
                            : null,

                    icon: const Icon(
                      Icons
                          .chevron_right,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),

      // -----------------------------------------
      // ADD TASK
      // -----------------------------------------

      floatingActionButton:
          FloatingActionButton(
        onPressed: () {
          showTaskDialog();
        },
        child:
            const Icon(Icons.add),
      ),
    );
  }

  // -----------------------------------------
  // DISPOSE
  // -----------------------------------------

  @override
  void dispose() {
    searchController.dispose();

    super.dispose();
  }
}