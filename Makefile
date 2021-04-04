
gen_diagrams:
	cat diagrams/base_architecture.py | docker run -i --rm -v ${PWD}/diagrams:/out gtramontina/diagrams:0.19.1
	cat diagrams/scaled_up_architecture.py | docker run -i --rm -v ${PWD}/diagrams:/out gtramontina/diagrams:0.19.1