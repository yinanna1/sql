今日主题：WHERE（行级过滤）+ NULL + LEFT JOIN 自连接

关键点 1:NULL 判断用 IS NULL / IS NOT NULL(不要 = NULL)

关键点 2：写 SQL 前先确认粒度：“一行代表什么？”

关键点 3：LEFT JOIN 保留左表全部行；匹配不到右表就显示 NULL

易错点：join 后行数变多 → 右表 key 可能不唯一 / join key 错

我今天跑通的验证：员工-经理 self join 查询 ✅

-Day2
这是行级过滤，所以用 WHERE。

两个条件都要满足，所以用 AND。

只要 product_id，所以 SELECT product_id。

-Day3
WHERE：先过滤“行”

GROUP BY：把行分组后再聚合

HAVING：对“组”做过滤（聚合后筛选）

条件计数：SUM(CASE WHEN 条件 THEN 1 ELSE 0 END)