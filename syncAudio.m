function [c] = syncAudio(videoIN, audioIN, FsIN, fileOutput, toll)

%syncAudio This function saves an audio file synchronized with another
%                 track from a video file.
%
%   [c] = syncAudio(video, audio, FsIN, fileOutput)
%
%   video       =   video master input
%   audio       =   audio slave from secondary audio track
%   FsIN        =   frequency
%   fileOutput  =   destination of final audio track  
%   toll        =   tollerance (in seconds)
%
%   IMPORTANT: the input files must have the same FsIN!
%
%   Copyright 2017 Giuseppe Gullotta and Liliana Scaffidi.
%   This code is made for the course of Digital Audio Processing 
%   of Politecnico di Torino.
%
%   We don't know if it works with all of the audio and video files
%   but we will try to solve it.
%
%   I prefer to use directly the delayFunction in this
%   code, to improve the time of computing
%
%   LIMITATION:   --> DRIFT: works only if audio is late compared to video
%                 --> GAP: it's possible to correct only silence gap
%         


% START 
fprintf('--------------\n');
fprintf('START\n')
fprintf('--------------\n');

% Check adaptive window for input files
fprintf('Read audio file\n')
audio = audioread(audioIN);
infoAudio = audioinfo(audioIN);

fprintf('Read video file\n')
infoVideo = audioinfo(videoIN);
video = audioread(videoIN);

fprintf('--------------\n')

minSamples = min(infoAudio.TotalSamples, infoVideo.TotalSamples);

% Check if audio files are longer than an hour
% window_length is for SyncFunction
% window_second is for DriftCheckFunction and DriftCorrectionFunction
if minSamples < 3600 * FsIN         % 60 minutes
    window_length = 30;             % 30 seconds
    window_second = 5;              % 5 seconds
else
    window_length = 60;             % 60 seconds
    window_second = 10;             % 10 seconds
end

% Check Sync Window
flag = 0;                   % Utility for while cycle
n = 0;                      % Counter
toll = FsIN * toll;         % Tollerance (in samples)
tAV_old = 0;                % Temporary variable
window_start = 1;           % First start interval

% Check Sync Function
fprintf('ANALISYS FILES\n')

while flag == 0

    window_end = FsIN * window_length * (n+1);
    
    % Sync Analysis in this window
    
    % Cross-Correlation function
    [AV, lagAV] = xcorr(audio(window_start:window_end), video(window_start:window_end));
    AV = AV/max(AV);

    [~, IAV] = max(AV);

    % Find delay in samples
    tAV = lagAV(IAV);
    
    % Print results of analysis
    fprintf('Segment %d  |  IN: %d  |  OUT: %d  -->  %d\n', n, window_start, window_end, tAV);
    
    % Check if segment is smaller than tollerance
    % it means that delay has been found
    if abs(tAV - tAV_old) <= toll
        flag = 1;
        % I prefer to use next window_end for a better result
        segment = [window_start, FsIN * window_length * (n+2)];    
    end
    
    tAV_old = tAV;
    n = n + 1;
    
    % Check if audio or video are finished
    if FsIN * window_length * (n+2) > infoAudio.TotalSamples || FsIN * window_length * (n+2) > infoVideo.TotalSamples
        error('Sync not found!');
    end

end

%Check if window_end is bigger than TotalSamples
if segment(2) > infoAudio.TotalSamples || segment(2) > infoVideo.TotalSamples
    segment(2) = minSamples;
end

% Print window analisys 
fprintf('--------------\n');
fprintf('Sync founded between %d and %d samples\n', segment(1), segment(2));
fprintf('--------------\n');

% Sync Function Start
fprintf('SYNC FILES\n')

% Sync Analisys in Segment


% Cross-Correlation function
[AV, lagAV] = xcorr(audio(segment(1):segment(2)), video(segment(1):segment(2)));
AV = AV/max(AV);

[~, IAV] = max(AV);

% Find delay in samples
tAV = lagAV(IAV);

% Print Delay both in Samples than in Second
fprintf('Delay: %d samples\n', tAV);
fprintf('Delay: %d seconds\n',tAV/FsIN);

% Return tAV
c = tAV;

% Sync Temporary Audio
y = audioread(audioIN);

% If tAV > 0 cut the first part of audio
% else add silence before starting time of audio
if tAV >= 0
    audioCut = y(tAV:end);
else
    h = zeros(-tAV, 1);
    audioCut = vertcat(h, y);
end


fprintf('--------------\n');

% Start Drift Analisys 
fprintf('DRIFT ANALISYS\n')

% Create new array for drift
minSamples = min(length(audioCut), infoVideo.TotalSamples);
sizeDrift = round(minSamples/(FsIN * window_second)) - 1;
drift = zeros(sizeDrift, 1);

% First window 
window_start = 1;
window_end = FsIN * window_second;

n = 1;  % Counter

h = waitbar(0, 'Drift Analisys...');

while window_end < minSamples
    
    % Cross-Correlation function
    [AV, lagAV] = xcorr(audioCut(window_start:window_end), video(window_start:window_end));
    AV = AV/max(AV);

    [~, IAV] = max(AV);

    % Find delay in samples
    drift(n) = lagAV(IAV);
    
    % Report drift values
    % fprintf('%d |  IN: %d OUT: %d  \t | \t Drift(%d) = %d \t|\n', n, window_start, window_end, n, drift(n));

    % Update window
    window_start = window_end + 1;
    window_end = (window_start - 1) + FsIN * window_second;
    n = n + 1;
    
    waitbar(n / sizeDrift);
    
end

close(h);

% Plot Drift
fprintf('--------------\n')
fprintf('PLOTTING DRIFT\n')

t_drift = (0 : FsIN * window_second : FsIN * (n-2) * window_second) / FsIN;

plot(t_drift, drift)
ylabel('video (s)');
xlabel('audio (s)');
title('DRIFT')

fprintf('--------------\n')

% Correction of gaps
fprintf('CORRECTION AUDIO GAPS\n')

tollSamp = 0.02;                % 20 ms tollerance
tollGap = tollSamp * FsIN;      % Tollerance in samples

offset = 0;
flag = true;

for n = 2 : length(drift)
    
    % Check difference between drift 
    if abs(drift(n) - drift(n-1)) > tollGap
        flag = false;
        window_start = ((n-1) * FsIN * window_second) + 1;
        window_end = n * FsIN * window_second;
        
        % if xcorr > 0   audio in advance  -->   add silence
        % if xcorr < 0   delayed audio     -->   remove samples
        
        % Cross-Correlation function
        [AV, lagAV] = xcorr(audioCut(window_start:window_end), video(window_start:window_end));
        AV = AV/max(AV);

        [~, IAV] = max(AV);

        % Find delay in samples
        tAV = lagAV(IAV);
        
        % Print gap founded
        fprintf('GAP @ %d\n', window_start+tAV);
        
        % Correction Gap
        if tAV > 0
           % Remove samples
           audioCut = vertcat(audioCut(1:window_start-offset), audioCut(window_start-offset+tAV:end));
        else
           % da implementare
        end
        
    end
    
end

if flag
    fprintf('No gap founded')
end
fprintf('--------------\n')

% Align Audio and Video
fprintf('ALIGN AUDIO AND VIDEO\n')

% this is useful both for final export and drift correction
% Video is master and it must not be touched

if length(audioCut) < infoVideo.TotalSamples
    % If video is longer than audio
    % add silence at the end of audio
    d = infoVideo.TotalSample - length(audioCut);
    h = zero(d, 1);
    audioCut = vertcat(audioCut, d);
else
    % If audio is longer than video
    % cut audio at the end 
    d = length(audioCut) - infoVideo.TotalSamples;
    audioCut = audioCut(1:end-d);
end

fprintf('--------------\n')

% Drift Correction
fprintf('DRIFT CORRECTION\n')

% Compute cross-correlation at the end of files and remove a single sample
% at every round(TotalSamples/tAV)

% Cross-Correlation function
[AV, lagAV] = xcorr(audioCut(end - FsIN * window_length : end), video(end - FsIN * window_length : end));
AV = AV/max(AV);

[~, IAV] = max(AV);

% Find delay in samples
tAV = lagAV(IAV);

% Print result
fprintf('Final drift: %d samples\n', tAV);
fprintf('--------------\n')

% Drift alignment
m = round(length(audioCut)/tAV);
sampleToBeDelete = zeros(m, 1);

t = length(audioCut);

fprintf('Calculate samples to be removed\n')

count = 1;
for n = 1:m:t
    sampleToBeDelete(count) = n;
    count = count + 1;
end

fprintf('Final Correction\n')

count = 1;
audioFinal = zeros(t,1);

for n = 1:length(audioCut)
    
    if n == sampleToBeDelete(count)
        count = count + 1;
    else
        audioFinal(n) = audioCut(n);
    end 
end


% Final Export
fprintf('--------------\n')
fprintf('Final Export\n')
audiowrite(fileOutput, audioFinal, FsIN);

% I have problem with ffmpeg installer 
% ffmpeg('-i', videoIN, '-i', 'audioSincronizzato.wav', fileOutput);

% End
fprintf('--------------\n')
fprintf('END\n')
fprintf('--------------\n')

end

