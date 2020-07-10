build-doc:
R -e "rmarkdown::render('training.Rmd')"

test: tests_python tests_r

test_r:
	echo "meh"