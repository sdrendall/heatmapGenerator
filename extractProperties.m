clear props area MajLen MinLen

for i = 1:8
    props = regionprops(labIm(:,:,i), 'Area', 'MajorAxisLength', 'MinorAxisLength');
    for iProp = 1:length(props)
        area(iProp, i) = props(iProp).Area;
        MajLen(iProp, i) = props(iProp).MajorAxisLength;
        MinLen(iProp, i) = props(iProp).MinorAxisLength;
    end
end