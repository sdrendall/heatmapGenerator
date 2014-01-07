function output = findMouse(paths)
% Attepts to locate a black mouse in an RBG image
% Uses the PARALLEL COMPUTING TOOLBOX
% Someday if I get smarter this might use a learning algorithm, that would
% be pretty cool...

% Some Parameters
bwThresh = .1;
resizeScale = .1;

% Allow 2 threads
parpool(2);

% Allocate Memory
% output = zeros([size(double(mat2gray(rgb2gray(imReadAndResize(paths{1}, resizeScale))))), length(paths)]);

% Begin Loop:
parfor i = 1:length(paths)
    % Read image
    % Downsample
    im = mat2gray(rgb2gray(imReadAndResize(paths{i}, resizeScale)));    
    
    % Segment
    im = 1 - im2bw(im, bwThresh);
    im = imclearborder(im);
    im = imclose(im, strel('disk', 3));    
    
    % Label
    im = logical(im);
    
    % Filter by Size
    props = regionprops(im, 'Area', 'MajorAxisLength', 'MinorAxisLength', 'Centroid');
    candidateLabels = [];
    winner = [];
    area = zeros(length(props), 1);
    
    % Test each labeled segment for appropriate area
    for iProp = 1:length(props)
        if props(iProp).Area >= 75 && props(iProp).Area <= 200
            candidateLabels = [candidateLabels, iProp];
        end
        area(iProp) = props(iProp).Area
    end
    
    
    % If multiple candidate segments exist, filter by shape
    if isempty(candidateLabels)
        winner = max(area);
    elseif length(candidateLabels) > 1
        for iLab = 1:length(candidateLabels)
            diff = props(iLab).MajorAxisLength - props(iLab).MinorAxisLength;
            if iLab == 1 || diff < previousDiff
                winner = candidateLabels(iLab);
            elseif diff == previousDiff
                % FLAG
            end
            previousDiff = diff;
        end
    elseif length(candidateLabels) == 1
        winner = candidateLabels;
        % FLAG HERE
    end
        
    % Save Centroid
    output(i).mouseCentroid = props(winner).Centroid;
    %output(i).filteredImage = im == winner;
    
    
end

% Resolve Conflicts (user input)

% Return Centroids

% Close parellel pool
delete(gcp)