function EEG = dataset_to_eeglab( dataset )
% Convert dataset from platforms conventions to EEGLAB format

	% First we need an empty set. These should match
	% eeglab 13_6_5b conventions.
	EEG = [];
	EEG.setname     = '';
	EEG.filename    = '';
	EEG.filepath    = '';
	EEG.subject     = '';
	EEG.group       = '';
	EEG.condition   = '';
	EEG.session     = [];
	EEG.comments    = '';
	EEG.nbchan      = 0;
	EEG.trials      = 0;
	EEG.pnts        = 0;
	EEG.srate       = 1;
	EEG.xmin        = 0;
	EEG.xmax        = 0;
	EEG.times       = [];
	EEG.data        = [];
	EEG.icaact      = [];
	EEG.icawinv     = [];
	EEG.icasphere   = [];
	EEG.icaweights  = [];
	EEG.icachansind = [];
	EEG.chanlocs    = [];
	EEG.urchanlocs  = [];
	EEG.chaninfo    = [];
	EEG.ref         = [];
	EEG.event       = [];
	EEG.urevent     = [];
	EEG.eventdescription = {};
	EEG.epoch       = [];
	EEG.epochdescription = {};
	EEG.reject      = [];
	EEG.stats       = [];
	EEG.specdata    = [];
	EEG.specicaact  = [];
	EEG.splinefile  = '';
	EEG.icasplinefile = '';
	EEG.dipfit      = [];
	EEG.history     = '';
	EEG.saved       = 'no';
	EEG.etc         = [];

	% fill it

	EEG.subject = 'SABRE';
	EEG.comments = 'Artificially generated';
	EEG.setname = dataset.id;
	EEG.session = 1;
	EEG.nbchan = size(dataset.X,2);
	EEG.pnts = size(dataset.X,1);
	EEG.data = dataset.X';
	EEG.srate = dataset.samplingFreq;
	EEG.xmin = 0;
	EEG.trials = 1;
	EEG.xmax = (EEG.pnts-1) / dataset.samplingFreq;
	EEG.times = (0:EEG.pnts-1) / dataset.samplingFreq;
	EEG.ref = 'common';

	for i=1:length(dataset.events)
		event = [];
		event.type = dataset.events(i).type;
		event.latency = dataset.events(i).latency;
		event.urevent = i;

		EEG.event = [EEG.event,event];
	end
	if(strcmp(EEG.event(end).type,'end'))
		% Seems EEGLAB doesn't plot the end marker unless its one sample early?
		EEG.event(end).latency = EEG.event(end).latency - 1;
	end
	
	EEG.urevent = EEG.event;
	EEG.urevent = rmfield(EEG.urevent, 'urevent');

	% @TODO should preferably get the real channel names here as well when available
	% also many location parameters of struct expected by eeglab are missing with the code below
	for i=1:EEG.nbchan
		chanlocs = [];
		chanlocs.labels = sprintf('%03d',i);
		chanlocs.X = dataset.electrodePos(i,1);
		chanlocs.Y = dataset.electrodePos(i,2);
		chanlocs.Z = dataset.electrodePos(i,3);
		chanlocs.type = 'EEG';
		EEG.chanlocs = [EEG.chanlocs;chanlocs];
	end

	% @TODO write the same function to eeglab->dataset direction for completeness

end

