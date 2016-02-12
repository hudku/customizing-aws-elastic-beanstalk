# .bashrc

# User specific aliases and functions

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'


# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi



export AWS_ELASTIC_BEANSTALK_HOME=/opt/aws/AWS-ElasticBeanstalk-CLI-2.2
if [ -e $AWS_ELASTIC_BEANSTALK_HOME ]; then
    export PATH=$PATH:$AWS_ELASTIC_BEANSTALK_HOME/api/bin
fi



# Run env.sh and generate env-result.sh if it does not exist
if [ ! -f ~/env-result.sh ]; then
    if [ -f ~/env.sh ]; then
        bash ~/env.sh
    fi
fi

# Use env-result.sh if present
if [ -f ~/env-result.sh ]; then
    # Get all the environment variables
    source ~/env-result.sh
fi
