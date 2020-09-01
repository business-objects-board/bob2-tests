update "database".busobj_posts set post_username = u.username 
    from "database".busobj_users u
    where u.user_id = poster_id;
