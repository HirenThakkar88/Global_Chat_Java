<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.util.*" %>
<%@ page import="utils.DBUtil" %>
<%@ page import="java.time.LocalDate" %>
<%@ page import="java.time.format.DateTimeFormatter" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.HashMap" %>

<%
    Integer loggedInUserId = (Integer) session.getAttribute("userId");
    if (loggedInUserId == null) {
        response.sendRedirect("LoginForm.jsp");
        return;
    }

    String groupIdParam = request.getParameter("groupId");
    String groupName = request.getParameter("groupName");

    if (groupIdParam == null || groupName == null) {
        response.sendRedirect("GroupList.jsp");
        return;
    }

    int groupId = 0;
    try {
        groupId = Integer.parseInt(groupIdParam);
        groupName = java.net.URLDecoder.decode(groupName, "UTF-8");
    } catch (Exception e) {
        response.sendRedirect("GroupList.jsp");
        return;
    }

    // Verify user is member of the group
    boolean isMember = false;
    Connection conn = null;
    PreparedStatement stmt = null;
    ResultSet rs = null;
    try {
        conn = DBUtil.getConnection();
        String sql = "SELECT 1 FROM group_members WHERE group_id = ? AND user_id = ?";
        stmt = conn.prepareStatement(sql);
        stmt.setInt(1, groupId);
        stmt.setInt(2, loggedInUserId);
        rs = stmt.executeQuery();
        isMember = rs.next();
    } catch (SQLException e) {
        out.println("Error verifying group membership: " + e.getMessage());
    } finally {
        DBUtil.close(conn, stmt, rs);
    }

    if (!isMember) {
        response.sendRedirect("GroupList.jsp");
        return;
    }
    // Get group members
    List<Map<String, Object>> groupMembers = new ArrayList<>();
    Connection membersConn = null;
    PreparedStatement membersStmt = null;
    ResultSet membersRs = null;
    try {
        membersConn = DBUtil.getConnection();
        String memberSql = "SELECT u.id, u.full_name, u.profile_pic " +
                          "FROM users u " +
                          "JOIN group_members gm ON u.id = gm.user_id " +
                          "WHERE gm.group_id = ?";
        membersStmt = membersConn.prepareStatement(memberSql);
        membersStmt.setInt(1, groupId);
        membersRs = membersStmt.executeQuery();
        
        while (membersRs.next()) {
            Map<String, Object> member = new HashMap<>();
            member.put("id", membersRs.getInt("id"));
            member.put("name", membersRs.getString("full_name"));
            member.put("profile_pic", membersRs.getString("profile_pic"));
            groupMembers.add(member);
        }
    } catch (SQLException e) {
        out.println("Error fetching group members: " + e.getMessage());
    } finally {
        DBUtil.close(membersConn, membersStmt, membersRs);
    }
%>
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Group Chat - <%= groupName %></title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://fonts.googleapis.com/css2?family=Noto+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        * {
            font-family: 'Noto Sans', sans-serif !important;
        }
        .navbar-space {
            height: 70px;
            margin-top: 0;
        }
        .attachment-menu {
            position: absolute;
            bottom: 70px;
            left: 20px;
            background: inherit;
            border-radius: 12px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.15);
            padding: 12px;
            display: none;
            z-index: 1000;
        }
        .attachment-item {
            display: flex;
            align-items: center;
            padding: 8px 16px;
            border-radius: 8px;
            transition: all 0.2s;
            cursor: pointer;
        }
        .attachment-item:hover {
            background: #f3f4f6;
        }
        .audio-player {
            width: 250px;
            margin: 10px 0;
        }
        .video-container {
            max-width: 400px;
            width: 100%;
            border-radius: 12px;
            overflow: hidden;
        }
        .video-player {
            width: 100%;
            height: auto;
            aspect-ratio: 16/9;
            background: #000;
        }
    </style>
    <style>
    .audio-player {
        width: 250px;
        margin: 10px 0;
    }
    .audio-player::-webkit-media-controls-panel {
        background-color: #f3f4f6;
    }
    </style>
</head>
<body class="min-h-screen bg-base-100 font-sans">
    <div class="navbar-container">
        <jsp:include page="Navbar.jsp" />
    </div>
    <div class="navbar-space"></div>

    <div class="flex h-screen">
        <jsp:include page="Slidebar.jsp" />

        <div class="flex-1 flex flex-col shadow-lg">
            <!-- Group Chat Header -->
            <div class="p-4 border-b flex items-center justify-between">
                <div class="flex items-center space-x-4 cursor-pointer" onclick="showMembersModal()">
                    <div class="w-12 h-12 rounded-full bg-primary flex items-center justify-center">
                        <span class="text-primary-content text-lg font-bold">#</span>
                    </div>
                    <div>
                        <p class="text-lg font-semibold "><%= groupName %></p>
                        <p class="text-sm ">Group Chat • <%= groupMembers.size() %> members</p>
            </div>
             </div>
                </div>
            

            <!-- Group Chat Messages -->
            <div class="flex-1 p-4 overflow-y-auto" id="chatWindow">
                <%
                    try {
                        conn = DBUtil.getConnection();
                        String sql = "SELECT m.*, u.full_name FROM messages m " +
                                     "JOIN users u ON m.sender_id = u.id " +
                                     "WHERE m.group_id = ? " +
                                     "ORDER BY m.created_at ASC";
                        stmt = conn.prepareStatement(sql);
                        stmt.setInt(1, groupId);
                        rs = stmt.executeQuery();

                        LocalDate lastDate = null;
                        while (rs.next()) {
                            int senderId = rs.getInt("sender_id");
                            String text = rs.getString("text");
                            String image = rs.getString("image");
                            String audio = rs.getString("audio");
                            String video = rs.getString("video");
                            String senderName = rs.getString("full_name");
                            Timestamp createdAt = rs.getTimestamp("created_at");
                            LocalDate messageDate = createdAt.toLocalDateTime().toLocalDate();

                            // Date formatting
                            LocalDate today = LocalDate.now();
                            LocalDate yesterday = today.minusDays(1);
                            String dateLabel;
                            
                            if (messageDate.equals(today)) {
                                dateLabel = "Today";
                            } else if (messageDate.equals(yesterday)) {
                                dateLabel = "Yesterday";
                            } else {
                                DateTimeFormatter formatter = DateTimeFormatter.ofPattern("MMMM d, yyyy");
                                dateLabel = messageDate.format(formatter);
                            }

                            if (lastDate == null || !messageDate.equals(lastDate)) {
                %>
                                <div class="date-header text-center text-gray-500 text-sm my-4">
                                    <%= dateLabel %>
                                </div>
                <%
                                lastDate = messageDate;
                            }
                            
                            boolean isSender = (senderId == loggedInUserId);
                %>
                            <div class="flex <%= isSender ? "justify-end" : "justify-start" %> mb-4">
                                <div class="<%= isSender ? "bg-primary text-primary-content" : "bg-neutral text-neutral-content" %> p-3 rounded-lg max-w-xs">
                                    <% if (!isSender) { %>
                                        <p class="text-xs font-semibold mb-1 <%= isSender ? "text-blue-100" : "text-gray-600" %>">
                                            <%= senderName %>
                                        </p>
                                    <% } %>
                                    
                                    <% if (image != null && !image.isEmpty()) { %>
                                        <img src="<%= image %>" alt="Attachment" class="mb-2 rounded-lg cursor-pointer max-w-full h-48 object-cover" onclick="window.open(this.src, '_blank')">
                                    <% } %>
                                    
                                    <% if (audio != null && !audio.isEmpty()) { %>
                                        <audio controls class="audio-player">
                                            <source src="<%= audio %>" type="audio/mpeg">
                                        </audio>
                                    <% } %>
                                    
                                    <% if (video != null && !video.isEmpty()) { %>
                                        <div class="video-container">
                                            <video controls class="video-player">
                                                <source src="<%= video %>" type="video/mp4">
                                            </video>
                                        </div>
                                    <% } %>
                                    
                                    <p><%= text %></p>
                                    <p class="text-xs mt-1 <%= isSender ? "bg-primary text-primary-content" : "bg-neutral text-neutral-content" %>" 
                                       data-timestamp="<%= createdAt.toInstant().toString() %>">
                                        <%= createdAt.toLocalDateTime().toLocalTime().toString().substring(0, 5) %>
                                    </p>
                                </div>
                            </div>
                <%
                        }
                    } catch (SQLException e) {
                        out.println("<p>Error loading messages: " + e.getMessage() + "</p>");
                    } finally {
                        DBUtil.close(conn, stmt, rs);
                    }
                %>
            </div>

            <!-- Group Chat Input -->
            <div class="p-4 border-t flex items-center gap-2 relative">
                <div class="relative">
                    <button id="plusButton"  class="p-2 bg-primary text-primary-content rounded-full hover:bg-primary-focus transition-colors">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
                        </svg>
                    </button>
                    
                    <!-- Attachment Menu -->
                    <div id="attachmentMenu" class="attachment-menu bg-base-100 border border-base-200">
                        <!-- Same attachment menu items as chatpage.jsp -->
                        <div class="attachment-item" onclick="handleAttachment('audio')">
                            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M19 11a7 7 0 01-7 7m0 0a7 7 0 01-7-7m7 7v4m0 0H8m4 0h4m-4-8a3 3 0 01-3-3V5a3 3 0 116 0v6a3 3 0 01-3 3z" />
                            </svg>
                            <span class="text-gray-700">Audio</span>
                        </div>
                        <div class="attachment-item" onclick="handleAttachment('photo')">
                            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                            </svg>
                            <span class="text-gray-700">Photo</span>
                        </div>
                        <div class="attachment-item" onclick="handleAttachment('video')">
                            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
                            </svg>
                            <span class="text-gray-700">Video</span>
                        </div>
                    </div>
                </div>

                <input type="text" id="messageInput" 
                       class="flex-1 p-2 border border-base-200 rounded-full px-4 bg-base-100 focus:outline-none focus:border-primary" 
                       placeholder="Type a message..."
                       onkeypress="if(event.keyCode === 13) sendMessage()">
                       

 <button type="button" 
            onclick="toggleEmojiPicker()"
            class="p-2 bg-primary text-primary-content rounded-full hover:bg-primary-focus transition-colors">
        😊 <!-- Smiley face emoji as default icon -->
    </button>
    
    <!-- Emoji Picker -->
    <div id="emojiPicker" 
         class="hidden absolute bottom-full mb-2 left-0 bg-base-100 border border-base-200 rounded-lg p-2 shadow-lg w-48 grid grid-cols-4 gap-2 z-50">
        <% String[] emojis = {
            "😀", "😁", "😂", "🤣", 
            "😃", "😄", "😅", "😆", 
            "😉", "😊", "😋", "😎", 
            "😍", "😘", "🥰", "😗"
        }; %>
        <% for(String emoji : emojis) { %>
            <button type="button" 
                    class="text-2xl p-1 hover:bg-base-200 rounded-lg transition-colors"
                    onclick="insertEmoji('<%= emoji %>')">
                <%= emoji %>
            </button>
        <% } %>
    </div>

                <button onclick="sendMessage()" class="p-2 bg-primary text-primary-content rounded-full hover:bg-primary-focus transition-colors">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 12L3 21l18-9-18-9-3 9zM11 12l8-4-8-4v8z"/>
                    </svg>
                </button>
            </div>
        </div>
         <!-- Members Modal -->
   <!-- Members Modal -->
<div id="membersModal" class="hidden fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center">
    <div class="bg-primary rounded-lg p-6 max-w-md w-full max-h-[80vh] overflow-y-auto">
        <div class="flex justify-between items-center mb-4">
            <h3 class="text-lg font-bold text-primary-content">Group Members</h3>
            <button onclick="closeMembersModal()" class=" bg-primary-focus">
                <!-- Close button -->
            </button>
        </div>
        <div class="space-y-4">
            <% for (Map<String, Object> member : groupMembers) { %>
                <div class="flex items-center space-x-3">
                    <div class="w-10 h-10 rounded-full overflow-hidden bg-gray-200">
                        <% if (member.get("profile_pic") != null && 
                              !((String) member.get("profile_pic")).isEmpty()) { %>
                            <img src="${pageContext.request.contextPath}<%= member.get("profile_pic") %>" 
                                 alt="Profile" 
                                 class="w-full h-full object-cover"
                                 onerror="this.style.display='none'; this.parentElement.querySelector('.default-avatar').style.display='flex';">
                            <div class="default-avatar w-full h-full hidden items-center justify-center text-gray-500">
                                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/>
                                </svg>
                            </div>
                        <% } else { %>
                            <div class="w-full h-full flex items-center justify-center text-gray-500">
                                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/>
                                </svg>
                            </div>
                        <% } %>
                    </div>
                    <span class="text-primary-content"><%= member.get("name") %></span>
                </div>
            <% } %>
        </div>
    </div>
</div>
    </div>
     <script>
let emojiPickerVisible = false;

function toggleEmojiPicker() {
    const picker = document.getElementById('emojiPicker');
    emojiPickerVisible = !emojiPickerVisible;
    picker.classList.toggle('hidden', !emojiPickerVisible);
    
    // Close other open menus if any
    document.getElementById('attachmentMenu').style.display = 'none';
}

function insertEmoji(emoji) {
    const input = document.getElementById('messageInput');
    input.value += emoji;
    input.focus();
    
    // Optionally send immediately
    // sendMessage();
}

// Close picker when clicking outside
document.addEventListener('click', (e) => {
    const picker = document.getElementById('emojiPicker');
    const emojiButton = e.target.closest('[onclick*="toggleEmojiPicker"]');
    
    if (!picker.contains(e.target) && !emojiButton) {
        picker.classList.add('hidden');
        emojiPickerVisible = false;
    }
});



</script>

    <script>
        // WebSocket Connection for Group Chat
      const websocket = new WebSocket('ws://localhost:8080/Global_Chat_Java/group-chat/<%= groupId %>');
        websocket.onmessage = function(event) {
            const message = JSON.parse(event.data);
            appendMessage(message);
        };

        function appendMessage(message) {
            const chatWindow = document.getElementById("chatWindow");
            const isSender = message.senderId === <%= loggedInUserId %>;
            const messageDate = new Date(message.timestamp);

            // Date handling (same as chatpage.jsp)
            // ... [include date handling logic from chatpage.jsp]
 const lastChild = chatWindow.lastElementChild;
    let lastDate = null;

    if (lastChild) {
        if (lastChild.classList.contains('date-header')) {
            // If last element is date header, check previous
            const prevElement = chatWindow.children[chatWindow.children.length - 2];
            if (prevElement) {
                const timeElement = prevElement.querySelector('[data-timestamp]');
                if (timeElement) lastDate = new Date(timeElement.dataset.timestamp);
            }
        } else {
            const timeElement = lastChild.querySelector('[data-timestamp]');
            if (timeElement) lastDate = new Date(timeElement.dataset.timestamp);
        }
    }
 // Format dates without time
    const currentDate = new Date(messageDate);
    currentDate.setHours(0, 0, 0, 0);
    
    const compareDate = lastDate ? new Date(lastDate) : null;
    if (compareDate) compareDate.setHours(0, 0, 0, 0);

    // Add date header if needed
    if (!lastDate || currentDate.getTime() !== compareDate.getTime()) {
        const dateHeader = document.createElement('div');
        dateHeader.className = 'date-header text-center text-primary-content text-sm my-4';
        //dateHeader.textContent = getDateLabel(messageDate);
        chatWindow.appendChild(dateHeader);
    }

            // Create message element
            const messageDiv = document.createElement("div");
            messageDiv.className = isSender ? "flex justify-end mb-4" : "flex justify-start mb-4";
            

            const contentDiv = document.createElement("div");
            contentDiv.className = isSender 
            ? "bg-primary text-primary-content p-3 rounded-lg max-w-xs" 
            : "bg-neutral text-neutral-content p-3 rounded-lg max-w-xs";
            
            if (message.image) {
                const img = document.createElement("img");
                img.src = message.image;
                img.alt = "Attachment";
                img.className = "mb-2 rounded-lg cursor-pointer max-w-full h-48 object-cover";
                img.onclick = () => window.open(img.src, '_blank');
                contentDiv.appendChild(img);
            } else if (message.audio) {
                const audio = document.createElement("audio");
                audio.controls = true;
                audio.className = "audio-player";
                const source = document.createElement("source");
                source.src = message.audio;
                source.type = "audio/mpeg";
                audio.appendChild(source);
                contentDiv.appendChild(audio);
            }else if (message.video) {
                const container = document.createElement("div");
                container.className = "video-container mb-2";
                
                const video = document.createElement("video");
                video.className = "video-player";
                video.controls = true;
                video.innerHTML = `
                    <source src="${message.video}" type="video/mp4">
                    Your browser does not support video tags
                `;
                
                container.appendChild(video);
                contentDiv.appendChild(container);
            }

            // Add sender name if not current user
            if (!isSender) {
                const senderName = document.createElement("p");
                senderName.className = "text-xs font-semibold mb-1 text-primary-content";
                senderName.textContent = message.senderName;
                contentDiv.appendChild(senderName);
            }

            
            const textElement = document.createElement("p");
            textElement.textContent = message.text;

            const timeElement = document.createElement('p');
            timeElement.className = isSender 
            ? "text-xs mt-1  text-primary-content" 
            : "text-xs mt-1  text-neutral-content";
            timeElement.textContent = messageDate.toLocaleTimeString([], {
                hour: '2-digit',
                minute: '2-digit'
            });

            contentDiv.appendChild(textElement);
            contentDiv.appendChild(timeElement);
            messageDiv.appendChild(contentDiv);
            chatWindow.appendChild(messageDiv);

            chatWindow.scrollTop = chatWindow.scrollHeight;
        }

        function sendMessage() {
            const messageInput = document.getElementById("messageInput");
            const messageText = messageInput.value.trim();
            
            if (messageText) {
                fetch("SendGroupMessage.jsp", {
                    method: "POST",
                    headers: { "Content-Type": "application/x-www-form-urlencoded" },
                    body: new URLSearchParams({
                        group_id: "<%= groupId %>",
                        text: messageText
                    })
                }).then(response => {
                    if (response.ok) {
                        messageInput.value = "";
                    }
                }).catch(error => console.error('Error:', error));
            }
        }
        function getDateLabel(date) {
            const today = new Date();
            today.setHours(0, 0, 0, 0);
            
            const yesterday = new Date(today);
            yesterday.setDate(today.getDate() - 1);

            const inputDate = new Date(date);
            inputDate.setHours(0, 0, 0, 0);

           
            
            return inputDate.toLocaleDateString('en-US', { 
                month: 'long', 
                day: 'numeric', 
                year: 'numeric' 
            });
        }
        

        document.getElementById('plusButton').addEventListener('click', function(e) {
            const menu = document.getElementById('attachmentMenu');
            menu.style.display = menu.style.display === 'block' ? 'none' : 'block';
            e.stopPropagation();
        });

        document.addEventListener('click', function(e) {
            if (!e.target.closest('#attachmentMenu') && !e.target.closest('#plusButton')) {
                document.getElementById('attachmentMenu').style.display = 'none';
            }
        });
        document.getElementById('emojiPicker').classList.add('hidden');
        emojiPickerVisible = false;

        function handleAttachment(type) {
            if (type === 'photo') {
                const input = document.createElement('input');
                input.type = 'file';
                input.accept = 'image/*';
                input.onchange = function(e) {
                    const file = e.target.files[0];
                    if (file) uploadImage(file);
                };
                input.click();
            }
           
         else if (type === 'audio') {
            const input = document.createElement('input');
            input.type = 'file';
            input.accept = 'audio/mp3';
            input.onchange = function(e) {
                const file = e.target.files[0];
                if (file) uploadFile(file, 'audio');
            };
            input.click();
        }
         else if (type === 'video') {
             const input = document.createElement('input');
             input.type = 'file';
             input.accept = 'video/mp4';
             input.onchange = function(e) {
                 const file = e.target.files[0];
                 if (file) uploadVideo(file);
             };
             input.click();
         }
         document.getElementById('attachmentMenu').style.display = 'none';
     }
        
        function uploadImage(file) {
            const formData = new FormData();
            formData.append('image', file);
            formData.append('groupId', '<%= groupId  %>');
            
            const text = document.getElementById('messageInput').value.trim();
            if (text) formData.append('text', text);

            fetch('UploadGroupImage.jsp', {
                method: 'POST',
                body: formData
            }).then(response => {
                if (!response.ok) {
                    // Get both header and body for debugging
                    const errorHeader = response.headers.get('X-Error-Msg');
                    return response.text().then(body => {
                        throw new Error(`Server Error [${errorHeader}]: ${body}`);
                    });
                }
                document.getElementById('messageInput').value = '';
            }).catch(error => {
                console.error('Upload Failed:', error);
                alert(error.message);
            });
        }
        function uploadFile(file, type) {
            const formData = new FormData();
            formData.append(type, file);
            formData.append('groupId', '<%= groupId  %>');
            
            const text = document.getElementById('messageInput').value.trim();
            if (text) formData.append('text', text);

            fetch('UploadGroupAudio.jsp', {
                method: 'POST',
                body: formData
            }).then(response => {
                if (!response.ok) {
                    return response.text().then(body => {
                        throw new Error(`Upload failed: ${body}`);
                    });
                }
                document.getElementById('messageInput').value = '';
            }).catch(error => {
                console.error('Error:', error);
                alert(error.message);
            });
        }
        
        function uploadVideo(file) {
            const formData = new FormData();
            formData.append('video', file);
            formData.append('groupId', '<%= groupId  %>');
            
            const text = document.getElementById('messageInput').value.trim();
            if (text) formData.append('text', text);

            fetch('GroupUploadVideo.jsp', {
                method: 'POST',
                body: formData
            }).then(response => {
                if (!response.ok) {
                    return response.text().then(body => {
                        throw new Error(`Video upload failed: ${body}`);
                    });
                }
                document.getElementById('messageInput').value = '';
            }).catch(error => {
                console.error('Video Error:', error);
                alert(error.message);
            });
        }
        
        // Member Modal Functions
        function showMembersModal() {
            const modal = document.getElementById('membersModal');
            if (modal) modal.classList.remove('hidden');
        }

        function closeMembersModal() {
            const modal = document.getElementById('membersModal');
            if (modal) modal.classList.add('hidden');
        }

        // Initialize click-outside handler
        document.addEventListener('DOMContentLoaded', () => {
            document.addEventListener('click', (event) => {
                const modal = document.getElementById('membersModal');
                if (event.target === modal) closeMembersModal();
            });
        });

    </script>
</body>
</html>