If you want to run istioctl dashboard prometheus in the background, you can use the nohup command along with the & operator. Here's how you can do it:

nohup istioctl dashboard prometheus &
This command will run the istioctl dashboard prometheus in the background and will redirect the output to a file named nohup.out in the current directory. The & at the end puts the command in the background.

If you want to redirect the output to a custom file, you can specify it after nohup, like this:

nohup istioctl dashboard prometheus > custom_output.log &

This way, the command will run in the background, and you can close the terminal without stopping the process. If you need to check the output later, you can examine the nohup.out or custom_output.log file.

To kill the process, run ps aux | grep "istioctl dashboard prometheus"
kill PID

curl -v $(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')