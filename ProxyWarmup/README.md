# Proxy Warmup

System designed to pound the proxy service to spool up a large number of instances in a short time. Useful for
getting the proxy ready for a class when many students will launch viewers at once. Note that these scripts assume
that gcloud is installed and that you have logged in with a personal ID that has IDC permissions.

Steps:

1. Optionally, create a `ProxyWarmup-SetEnv.sh` file to configure the system to your project, targets, and VM 
   parameters. All the scripts use the parameters to work in concert with each other. Otherwise, you need
   to set environment variables in each script. See `ProxyWarmup-SetEnv-Example.sh`
2. Run `createBQTable.sh` to create a local copy of the BQ table that holds all the requests that will be issued.
   Note that this assumes you have read permissions on the project where the source table lives.
3. Run `createSleepFromDesktop.sh` to build the machine and sleep it. This takes a while to set up the machine and
   install the dependencies.
4. Run `wakeRunSleepFromDesktop.sh` to wake the machine, run the warmup script, and put the machine back to sleep.
5. For one-stop shopping (though you still need to copy the BQ table into your project before running this) run
   `createRunDestroyFromDesktop.sh` This will create the machine, run the script, and delete the machine. BQ table
   you created is untouched.
