use Cwd 'abs_path';

my $root = abs_path("$ENV{TEXMF_MAIN_DIR}" || "$ENV{PWD}" || '.');
my $build_dir = "$root/build";
my $log_dir = "$root/log";

$pdf_mode = 1;
$out_dir = $build_dir;

$pdflatex = "pdflatex -interaction=nonstopmode -output-directory=$build_dir %O %S";

foreach my $dir ($build_dir, $log_dir) {
    mkdir $dir unless -d $dir;
}

sub get_base_name {
    my $file = $ENV{'LATEXMK_TEXFILE'} || $ARGV[0] || 'main.tex';
    $file =~ s|\\|/|g;
    $file =~ s|^.*/||;
    $file =~ s|\.tex$||i;
    return $file;
}

$cleanup_ext = 'aux bbl blg fdb_latexmk fls log out toc synctex.gz';
$post_run = sub {
    my $base = get_base_name();
    foreach my $ext (split ' ', $cleanup_ext) {
        my $src = "$build_dir/${base}.${ext}";
        if (-e $src) {
            system("move /Y \"$src\" \"$log_dir\\\"");
        }
    }
};

$pdf_previewer = 'start';

$ENV{'TEXINPUTS'} = ".:$ENV{HOME}/Documents/GitHub/LatexCV/roles_CVs/__2._photos//:$ENV{HOME}/Documents/GitHub/LatexCV/roles_CVs/__3._sections//:.:$ENV{HOME}/Documents/GitHub/LatexCV/roles_CVs/__1._images//:";
