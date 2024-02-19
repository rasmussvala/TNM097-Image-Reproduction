function final = floodFill(img, startRow, startCol, fillColor)
% Implements a 4-connected flood fill algorithm

[numRows, numCols, ~] = size(img);
final = img; % Create a copy to modify

% Check if starting pixel is close to white
threshold = 245;
if ~all(img(startRow, startCol, :) >= threshold)
    return; % No fill needed if not close to white
end

stack = [startRow startCol];

while ~isempty(stack)
    pixel = stack(end, :);
    stack(end, :) = []; % Pop
    row = pixel(1);
    col = pixel(2);

    % Check if already filled
    if ~all(final(row, col, :) == fillColor)
        final(row, col, :) = fillColor;

        % Add valid neighbors to the stack (4-connectivity)
        if row > 1 && all(img(row - 1, col, :) >= threshold)
            stack = [stack; row - 1 col];
        end
        if row < numRows && all(img(row + 1, col, :) >= threshold)
            stack = [stack; row + 1 col];
        end
        if col > 1 && all(img(row, col - 1, :) >= threshold)
            stack = [stack; row col - 1];
        end
        if col < numCols && all(img(row, col + 1, :) >= threshold)
            stack = [stack; row col + 1];
        end
    end
end

end
