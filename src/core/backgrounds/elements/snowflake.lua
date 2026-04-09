local Xuehua = {}

function Xuehua.draw(x, y, s, variant, alpha, glint, front)
    -- 设置默认值
    variant = variant or 1
    alpha = alpha or 1
    s = s or 1

    -- 计算基础像素缩放
    local u = math.max(1, math.floor(s + 0.5))
    
    -- 如果是前景雪花，整体可以稍微放大或变亮（这里用透明度稍高来表现）
    if front then
        alpha = math.min(1, alpha * 1.2)
    end

    -- 设置为纯白色，带透明度
    love.graphics.setColor(1, 1, 1, alpha)

    -- 为了保证像素对齐，坐标取整
    local px = math.floor(x + 0.5)
    local py = math.floor(y + 0.5)

    if variant == 1 then
        -- 形态 1：1x1 的极小像素点 (远景雪)
        love.graphics.rectangle("fill", px, py, u, u)

    elseif variant == 2 then
        -- 形态 2：2x2 的小方块 (中景雪，最经典)
        love.graphics.rectangle("fill", px, py, u * 2, u * 2)

    else
        -- 形态 3：3x3 削去四个角的“圆”点 (近景雪/大雪花)
        -- 画一个横向 3x1，再画一个纵向 1x3，拼成一个像素十字圆点
        love.graphics.rectangle("fill", px + u, py, u, u * 3)
        love.graphics.rectangle("fill", px, py + u, u * 3, u)
    end
end

return Xuehua