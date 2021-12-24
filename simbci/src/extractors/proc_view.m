

classdef proc_view
% elementary plugin to view data during the process call. Returns data as-is pass-through.

	properties
		usedParams
	end

	methods

	function [ obj,feats ] = train(obj, trainData, varargin)

		% parse arguments
		p = inputParser;
		p.KeepUnmatched = false;
		p.CaseSensitive = true;
		p.PartialMatching = false;

		addParameter(p, 'method',                 'image',      @ischar);
		addParameter(p, 'title',                  '',           @ischar);
		addParameter(p, 'sampleSet',              [],           @isnumeric); % empty = all
		addParameter(p, 'channelSet',             [],           @isnumeric); % empty = all
		addParameter(p, 'normalizeDirection',     0,            @isint); % 0  == none, 1 == columns, 2 == rows
		addParameter(p, 'bypass',                 false,        @islogical);

		p.parse(varargin{:});
		obj.usedParams = p.Results;

		%%%%%

		feats = [];

	end

	function feats = process(obj, data)

		params = obj.usedParams;

		if(params.bypass)
			feats = data.X;
			return;
		end

		% Take subset of data?
		if(isempty(params.sampleSet))
			params.sampleSet = 1:size(data.X,1);
		end
		if(isempty(params.channelSet))
			params.channelSet = 1:size(data.X,2);
		end

		tmp = data.X(params.sampleSet,params.channelSet);

		if(params.normalizeDirection~=0)
			tmp = normalize(tmp,[],[],params.normalizeDirection);
		end

		figure();
		if(isequal(params.method,'image'))
			imagesc(tmp);
			xlabel('Channel');ylabel('Time');
		elseif(isequal(params.method,'spectrogram'))
			for i=1:size(tmp,2)
				if(i>1)
					figure();
				end
				spectrogram(tmp(:,i),[],[],[],data.samplingFreq);
				tit = sprintf('Chn %03d', params.channelSet(i));
				title(tit);
			end
		elseif(isequal(params.method,'periodogram'))
			periodogram(tmp,[],[],data.samplingFreq);
			leg = obj.makelegend(params.channelSet);
			% leg = sprintf('Channels %s', num2str(params.channelSet));
			legend(leg{:});
		elseif(isequal(params.method,'plot'))
			subplots = ceil(sqrt(size(tmp,2)));

			yMin = min(tmp(:));
			yMax = max(tmp(:));
			for i=1:size(tmp,2)
				subplot(subplots,subplots,i);
				plot((params.sampleSet-1)/data.samplingFreq, tmp(:,i));
				ylim([yMin yMax]);
				title(sprintf('chn %03d', params.channelSet(i)));
			end
			%	leg = obj.makelegend(params.channelSet);
			% leg = sprintf('Channels %s', num2str(params.channelSet));
			%legend(leg{:}); xlabel('Time'); ylabel('Value');
		elseif(isequal(params.method,'corrcoef'))
			imagesc(corrcoef(tmp));
			xlabel('Channel');ylabel('Channel');
		else
			assert(false, sprintf('Unknown method ''%s''', params.method));
		end

		if(isempty(params.title))
			tit = params.method;
		else
			tit = params.title;
		end

		if(isempty(get(get(gca,'title'),'string')))
			title(sprintf('View ''%s'' (set ''%s'')', tit, data.id));
		end

		drawnow;

		% just a passthrough
		feats = data.X;

	end

	end

	methods (Access = private)

		function leg = makelegend(~, channelSet)

			leg = cell(length(channelSet),1);
			for i=1:length(channelSet)
				leg{i} = sprintf('Chn %03d', channelSet(i));
			end

		end

	end

end



