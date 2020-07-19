%Copyright 2019-2020 The MathWorks, Inc.

function failed = runMatlabTests(varargin)

p = inputParser;
validationFcn = @(c)ischar(c) && (isempty(c) || isrow(c));

p.addParameter('PDFReportPath', '', validationFcn);
p.addParameter('TAPResultsPath', '', validationFcn);
p.addParameter('JUnitResultsPath', '', validationFcn);
p.addParameter('SimulinkTestResultsPath', '', validationFcn);
p.addParameter('CoberturaCodeCoveragePath', '', validationFcn);
p.addParameter('CoberturaModelCoveragePath', '', validationFcn);

p.parse(varargin{:});


pdfReportPath            = p.Results.PDFReportPath;
tapReportPath            = p.Results.TAPResultsPath;
junitReportPath          = p.Results.JUnitResultsPath;
stmReportPath            = p.Results.SimulinkTestResultsPath;
coberturaReportPath      = p.Results.CoberturaCodeCoveragePath;
modelCoveragePath        = p.Results.CoberturaModelCoveragePath;

BASE_VERSION_MATLABUNIT_SUPPORT = '8.1';

if verLessThan('matlab',BASE_VERSION_MATLABUNIT_SUPPORT)
    error('MATLAB:unitTest:testFrameWorkNotSupported','Running tests automatically is not supported in this relase.');
end

%Create test suite for tests folder
suite = getTestSuite();

% Create and configure the runner
import('matlab.unittest.TestRunner');
runner = TestRunner.withTextOutput;



% Produce JUnit report
if ~isempty(junitReportPath)
    BASE_VERSION_JUNIT_SUPPORT = '8.6';
    if verLessThan('matlab',BASE_VERSION_JUNIT_SUPPORT)
        warning('MATLAB:testArtifact:junitReportNotSupported', 'Producing JUnit xml results is not supported in this release.');
    else
        import('matlab.unittest.plugins.XMLPlugin');
        preparePath(junitReportPath);
        runner.addPlugin(XMLPlugin.producingJUnitFormat(junitReportPath));
    end
end

% Produce TAP report
if ~isempty(tapReportPath)
    BASE_VERSION_TAPORIGINALFORMAT_SUPPORT = '8.3';
    BASE_VERSION_TAP13_SUPPORT = '9.1';
    if verLessThan('matlab',BASE_VERSION_TAPORIGINALFORMAT_SUPPORT)
        warning('MATLAB:testArtifact:tapReportNotSupported', 'Producing TAP results is not supported in this release.');
    elseif verLessThan('matlab',BASE_VERSION_TAP13_SUPPORT)
        tapFile = getTapResultFile(tapReportPath);
        import('matlab.unittest.plugins.TAPPlugin');
        tapPlugin = TAPPlugin.producingOriginalFormat(tapFile);
        runner.addPlugin(tapPlugin);
    else
        tapFile = getTapResultFile(tapReportPath);
        import('matlab.unittest.plugins.TAPPlugin');
        tapPlugin = TAPPlugin.producingVersion13(tapFile);
        runner.addPlugin(tapPlugin);
    end
    
end

% Produce Cobertura report (Cobertura report generation is not supported
% below R17a) 
if ~isempty(coberturaReportPath) 
    BASE_VERSION_COBERTURA_SUPPORT = '9.3';
    
    if verLessThan('matlab',BASE_VERSION_COBERTURA_SUPPORT)
         warning('MATLAB:testArtifact:coberturaReportNotSupported', 'Producing Cobertura code coverage results is not supported in this release.');
    else 
        import('matlab.unittest.plugins.CodeCoveragePlugin');
        preparePath(coberturaReportPath);
        workSpace = fullfile(pwd);
        runner.addPlugin(CodeCoveragePlugin.forFolder(workSpace,'IncludingSubfolders',true,...
        'Producing', CoberturaFormat(coberturaReportPath)));
    end
end

% Produce Cobertura model coverage report (Not supported below R2018b) 
if ~isempty(modelCoveragePath)
    if ~exist('sltest.plugins.ModelCoveragePlugin', 'class') || ~coberturaModelCoverageSupported
        warning('MATLAB:testArtifact:cannotGenerateModelCoverageReport', ...
                'Unable to generate Cobertura model coverage report. To generate the report, use a Simulink Coverage license with MATLAB R2018b or a newer release.');
    else 
        import('sltest.plugins.ModelCoveragePlugin');
        
        preparePath(modelCoveragePath);
        runner.addPlugin(ModelCoveragePlugin('Producing',CoberturaFormat(modelCoveragePath)));
    end
end

stmResultsPluginAddedToRunner = false;

% Save Simulink Test Manager results in MLDATX format (Not supported below R2019a)
if ~isempty(stmReportPath)
    if ~stmResultsPluginPresent || ~exportSTMResultsSupported
        issueExportSTMResultsUnsupportedWarning;
    else
        preparePath(stmReportPath);
        runner.addPlugin(TestManagerResultsPlugin('ExportToFile', stmReportPath));
        stmResultsPluginAddedToRunner = true;
    end
end

% Produce PDF test report (Not supported on MacOS platforms and below R2017a)
if ~isempty(pdfReportPath)
    if ismac
        warning('MATLAB:testArtifact:unSupportedPlatform', ...
            'Producing a PDF test report is not currently supported on MacOS platforms.');
    elseif ~testReportPluginPresent
        issuePDFReportUnsupportedWarning;
    else
        preparePath(pdfReportPath);
        import('matlab.unittest.plugins.TestReportPlugin');
        runner.addPlugin(TestReportPlugin.producingPDF(pdfReportPath));
        
        if ~stmResultsPluginAddedToRunner && stmResultsPluginPresent
            runner.addPlugin(TestManagerResultsPlugin);
        end
    end
end

results = runner.run(suite);
failed = any([results.Failed]);

function preparePath(path)
dir = fileparts(path);
dirExists = isempty(dir) || exist(dir,'dir') == 7;
if ~dirExists		
    mkdir(dir);		    
end

function tapFile = getTapResultFile(resultsDir)
import('matlab.unittest.plugins.ToFile');
preparePath(resultsDir);
fclose(fopen(resultsDir,'w'));
tapFile = matlab.unittest.plugins.ToFile(resultsDir);

function suite = getTestSuite()
import('matlab.unittest.TestSuite');
BASE_VERSION_TESTSUITE_SUPPORT = '9.0';
if verLessThan('matlab',BASE_VERSION_TESTSUITE_SUPPORT)
    suite = matlab.unittest.TestSuite.fromFolder(pwd,'IncludingSubfolders',true);
else
    suite = testsuite(pwd,'IncludeSubfolders',true);
end

function plugin = CoberturaFormat(varargin)
plugin = matlab.unittest.plugins.codecoverage.CoberturaFormat(varargin{:});

function plugin = TestManagerResultsPlugin(varargin)
plugin = sltest.plugins.TestManagerResultsPlugin(varargin{:});

function tf = testReportPluginPresent
BASE_VERSION_REPORTPLUGIN_SUPPORT = '9.2'; % R2017a 

tf = ~verLessThan('matlab',BASE_VERSION_REPORTPLUGIN_SUPPORT);

function tf = stmResultsPluginPresent
tf = logical(exist('sltest.plugins.TestManagerResultsPlugin', 'class'));

function tf = coberturaModelCoverageSupported
BASE_VERSION_MODELCOVERAGE_SUPPORT = '9.5'; % R2018b

tf = ~verLessThan('matlab',BASE_VERSION_MODELCOVERAGE_SUPPORT);

function tf = exportSTMResultsSupported
BASE_VERSION_EXPORTSTMRESULTS_SUPPORT = '9.6'; % R2019a

tf = ~verLessThan('matlab',BASE_VERSION_EXPORTSTMRESULTS_SUPPORT);

function issuePDFReportUnsupportedWarning
warning('MATLAB:testArtifact:pdfReportNotSupported', ...
    'Producing a test report in PDF format is not supported in the current MATLAB release.');

function issueExportSTMResultsUnsupportedWarning
warning('MATLAB:testArtifact:cannotExportSimulinkTestManagerResults', ...
    ['Unable to export Simulink Test Manager results. This feature ', ...
    'requires a Simulink Test license and is supported only in MATLAB R2019a or a newer release.']);
