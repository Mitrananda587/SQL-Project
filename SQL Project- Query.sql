USE Social_Media;
show tables;
select count(*) from users;
select count(*) from posts;

-- -----------------------------------
-- Start solving project questions.
-- -----------------------------------

-- ---------------------------------------------------------
-- Q1. Find the top 10 most active uses (posts + comments).
-- ----------------------------------------------------------
SELECT u.username,
    COUNT(DISTINCT p.post_id) AS total_posts,
    COUNT(DISTINCT c.comment_id) AS total_comments,
    COUNT(DISTINCT p.post_id) +
    COUNT(DISTINCT c.comment_id) AS total_activity
FROM users u
LEFT JOIN posts p
    ON u.user_id = p.user_id
LEFT JOIN comments c
    ON u.user_id = c.user_id
GROUP BY u.user_id, u.username
ORDER BY total_activity DESC
LIMIT 10;

-- ----------------------------------------------------------
-- Q2. Find the top 10 most liked posts.
-- -----------------------------------------------------------
SELECT p.post_id, u.username,
    COUNT(l.like_id) AS total_likes
FROM posts p
JOIN users u
    ON p.user_id = u.user_id
LEFT JOIN likes l
    ON p.post_id = l.post_id
GROUP BY p.post_id, u.username
ORDER BY total_likes DESC
LIMIT 10; 

-- ---------------------------------------------------------
-- Q2. Find the top 10 most liked posts and their creators. 
-- ---------------------------------------------------------
SELECT
    p.post_id,
    p.content,
    u.username,
    COUNT(l.like_id) AS total_likes
FROM posts p
JOIN users u
    ON p.user_id = u.user_id
LEFT JOIN likes l
    ON p.post_id = l.post_id
GROUP BY
    p.post_id,
    p.content,
    u.username
ORDER BY total_likes DESC
LIMIT 10;

-- ----------------------------------------------------
-- Q3. Find the top 5 countries by average engagement 
-- ---------------------------------------------------- 
SELECT
    u.country,
    COUNT(DISTINCT p.post_id) AS total_posts,
    COUNT(l.like_id) AS total_likes,
    ROUND(
        COUNT(l.like_id) /
        COUNT(DISTINCT p.post_id), 2
    ) AS average_likes_per_post
FROM users u
JOIN posts p
    ON u.user_id = p.user_id
LEFT JOIN likes l
    ON p.post_id = l.post_id
GROUP BY u.country
ORDER BY average_likes_per_post DESC
LIMIT 5;


-- -------------------------------------------------------
-- Q4. Discover trending hashtags used in more then 20 posts.
-- -------------------------------------------------------
SELECT h.tag_name,
    COUNT(ph.post_id) AS total_posts
FROM hashtags h
JOIN post_hashtags ph
    ON h.hashtag_id = ph.hashtag_id
GROUP BY h.hashtag_id, h.tag_name
HAVING COUNT(ph.post_id) > 20
ORDER BY total_posts DESC;



-- ---------------------------------------------------------
-- Top Countries by Average Engagement Rate?
-- ----------------------------------------------------------

SELECT u.country,
    COUNT(DISTINCT p.post_id) AS total_posts,
    COUNT(DISTINCT l.like_id) AS total_likes,
    COUNT(DISTINCT c.comment_id) AS total_comments,
    
    ROUND((COUNT(DISTINCT l.like_id) +
            COUNT(DISTINCT c.comment_id)) /
            COUNT(DISTINCT p.post_id), 2) AS average_engagement_rate
FROM users u
JOIN posts p
    ON u.user_id = p.user_id
LEFT JOIN likes l
    ON p.post_id = l.post_id
LEFT JOIN comments c
    ON p.post_id = c.post_id
GROUP BY u.country
ORDER BY average_engagement_rate DESC;


-- -------------------------------------------------------------------
-- Q6. Find users who follow other people but never like or comment
-- -------------------------------------------------------------------
SELECT u.user_id, u.username
FROM users u
WHERE EXISTS (
    SELECT 1
    FROM followers f
    WHERE f.follower_user_id = u.user_id
)
AND NOT EXISTS (
    SELECT 1
    FROM likes l
    WHERE l.user_id = u.user_id
)
AND NOT EXISTS (
    SELECT 1
    FROM comments c
    WHERE c.user_id = u.user_id
);

-- -----------------------------------------------------------------
-- Q7. Find hashtags with the highest engagement(likes + comments)
-- --------------------------------------------------------------------

WITH like_counts AS (
    SELECT
        post_id,
        COUNT(*) AS total_likes
    FROM likes
    GROUP BY post_id
),
comment_counts AS (
    SELECT
        post_id,
        COUNT(*) AS total_comments
    FROM comments
    GROUP BY post_id
),
post_engagement AS (
    SELECT
        p.post_id,
        COALESCE(l.total_likes, 0) AS total_likes,
        COALESCE(c.total_comments, 0) AS total_comments
    FROM posts p
    LEFT JOIN like_counts l
        ON p.post_id = l.post_id
    LEFT JOIN comment_counts c
        ON p.post_id = c.post_id
)
SELECT
    h.tag_name,
    SUM(pe.total_likes) AS total_likes,
    SUM(pe.total_comments) AS total_comments,
    SUM(pe.total_likes + pe.total_comments)
        AS total_engagement
FROM hashtags h
JOIN post_hashtags ph
    ON h.hashtag_id = ph.hashtag_id
JOIN post_engagement pe
    ON ph.post_id = pe.post_id
GROUP BY
    h.hashtag_id,
    h.tag_name
ORDER BY total_engagement DESC;

-- -------------------------------------------------------------
-- Q8. Identify the busiest hours or days for posting activity. 
-- -------------------------------------------------------------
SELECT
    HOUR(created_at) AS posting_hour,
    COUNT(*) AS total_posts
FROM posts
GROUP BY HOUR(created_at)
ORDER BY total_posts DESC;

SELECT
    DAYNAME(created_at) AS posting_day,
    COUNT(*) AS total_posts
FROM posts
GROUP BY DAYNAME(created_at)
ORDER BY total_posts DESC;

-- --------------------------------------------------------
-- Q9. Identify inactive users (no posts,likes or comments)
-- --------------------------------------------------------
SELECT
    u.user_id,
    u.username,
    u.country
FROM users u
WHERE NOT EXISTS (
    SELECT 1
    FROM posts p
    WHERE p.user_id = u.user_id
)
AND NOT EXISTS (
    SELECT 1
    FROM likes l
    WHERE l.user_id = u.user_id
)
AND NOT EXISTS (
    SELECT 1
    FROM comments c
    WHERE c.user_id = u.user_id
);

-- --------------------------------------------------------
-- Q10. Find the top 5 countries with the most influencers. 
-- ---------------------------------------------------------
WITH follower_counts AS (
    SELECT
        user_id,
        COUNT(*) AS total_followers
    FROM followers
    GROUP BY user_id
)
SELECT
    u.country,
    COUNT(u.user_id) AS total_influencers,
    SUM(fc.total_followers) AS total_followers
FROM users u
JOIN follower_counts fc
    ON u.user_id = fc.user_id
GROUP BY u.country
ORDER BY total_influencers DESC
LIMIT 5;

-- Bonus Question.
-- -------------------------------------------------------
-- QB1. Engagement rate calculation.
-- --------------------------------------------------------
SELECT
    COUNT(DISTINCT p.post_id) AS total_posts,
    COUNT(DISTINCT l.like_id) AS total_likes,
    COUNT(DISTINCT c.comment_id) AS total_comments,
    ROUND((COUNT(DISTINCT l.like_id) +
            COUNT(DISTINCT c.comment_id)) * 100.0 /
        COUNT(DISTINCT p.post_id),2) AS engagement_rate
FROM posts p
LEFT JOIN likes l
    ON p.post_id = l.post_id
LEFT JOIN comments c
    ON p.post_id = c.post_id;
    
-- -------------------------------------------------------
-- QB2. Mutual followers.
-- ------------------------------------------------------
SELECT
    u1.username AS user_1,
    u2.username AS user_2
FROM followers f1
JOIN followers f2
    ON f1.user_id = f2.follower_user_id
   AND f1.follower_user_id = f2.user_id
JOIN users u1
    ON f1.user_id = u1.user_id
JOIN users u2
    ON f1.follower_user_id = u2.user_id
WHERE f1.user_id < f1.follower_user_id;    

-- -----------------------------------------------
-- QB3. Hashtags used by the top 5 influencers.
-- -------------------------------------------------
WITH top_influencers AS (
    SELECT
        u.user_id,
        u.username,
        COUNT(f.follower_id) AS total_followers
    FROM users u
    LEFT JOIN followers f
        ON u.user_id = f.user_id
    GROUP BY u.user_id, u.username
    ORDER BY total_followers DESC
    LIMIT 5
)

SELECT
    ti.username,
    ti.total_followers,
    h.tag_name,
    COUNT(DISTINCT p.post_id) AS total_posts
FROM top_influencers ti
JOIN posts p
    ON ti.user_id = p.user_id
JOIN post_hashtags ph
    ON p.post_id = ph.post_id
JOIN hashtags h
    ON ph.hashtag_id = h.hashtag_id
GROUP BY
    ti.user_id,
    ti.username,
    ti.total_followers,
    h.hashtag_id,
    h.tag_name
ORDER BY
    ti.total_followers DESC,
    total_posts DESC;
    
-- ---------------------------------------------------------
-- QB4. Country-wise engagement leaderboard.
-- ---------------------------------------------------------
WITH country_engagement AS (SELECT u.country,
        COUNT(DISTINCT p.post_id) AS total_posts,
        COUNT(DISTINCT l.like_id) AS total_likes,
        COUNT(DISTINCT c.comment_id) AS total_comments,
        (COUNT(DISTINCT l.like_id) +COUNT(DISTINCT c.comment_id)
        ) AS total_engagement
    FROM users u
    JOIN posts p
        ON u.user_id = p.user_id
    LEFT JOIN likes l
        ON p.post_id = l.post_id
    LEFT JOIN comments c
        ON p.post_id = c.post_id
    GROUP BY u.country
)
SELECT RANK() OVER (
	ORDER BY total_engagement DESC
    ) AS country_rank,
    country,
    total_posts,
    total_likes,
    total_comments,
    total_engagement,
    ROUND(total_engagement * 100.0 / total_posts, 2
) AS engagement_per_100_posts
FROM country_engagement
ORDER BY country_rank;    
